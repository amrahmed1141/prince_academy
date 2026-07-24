import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prince_academy/features/admin/data/models/active_user_model.dart';
import 'package:prince_academy/features/admin/data/models/branch_model.dart';
import 'package:prince_academy/features/admin/data/models/coach_user_stats_model.dart';
import 'package:prince_academy/features/admin/data/models/paged_result.dart';
import 'package:prince_academy/features/admin/data/repositories/branch_repository.dart';
import 'package:prince_academy/features/admin/data/repositories/coach_repository.dart';
import 'package:prince_academy/features/admin/presentation/bloc/tracking/tracking_event.dart';
import 'package:prince_academy/features/admin/presentation/bloc/tracking/tracking_state.dart';

class TrackingBloc extends Bloc<TrackingEvent, TrackingState> {
  final CoachRepository repository;
  final BranchRepository branchRepository;

  int _requestId = 0;
  bool _hasMoreFromServer = true;
  RealtimeChannel? _trackingRealtimeChannel;
  Timer? _realtimeDebounce;
  Timer? _pollTimer;
  bool _hasLoadedOnce = false;

  TrackingBloc({
    required this.repository,
    required this.branchRepository,
  }) : super(const TrackingInitial()) {
    on<LoadTrackingData>(_onLoadTrackingData);
    on<LoadMoreSubscribers>(_onLoadMoreSubscribers);
    on<SearchUsers>(_onSearchUsers);
    on<FilterByCoach>(_onFilterByCoach);
    on<FilterByBranch>(_onFilterByBranch);
    on<LoadUserDetail>(_onLoadUserDetail);
    on<LoadWeeklyAttendance>(_onLoadWeeklyAttendance);
    _ensureRealtimeSubscription();
    _startPolling();
  }

  Future<void> _onLoadTrackingData(
    LoadTrackingData event,
    Emitter<TrackingState> emit,
  ) async {
    final current = state;
    final currentLoaded = current is TrackingLoaded ? current : null;
    final selectedCoachId = currentLoaded?.selectedCoachId;
    final selectedBranchId = currentLoaded?.selectedBranchId;
    final searchQuery = currentLoaded?.searchQuery;

    final requestId = ++_requestId;

    if (event.silent && current is TrackingLoaded) {
      emit(current.copyWith(isRefreshing: true, clearLoadMoreError: true));
    } else if (current is TrackingLoaded) {
      emit(current.copyWith(isRefreshing: true, clearLoadMoreError: true));
    } else {
      emit(const TrackingLoading());
    }

    try {
      final results = await Future.wait([
        repository.getCoachUserStats(),
        branchRepository.getAllBranches(),
        repository.getMembers(
          limit: TrackingLoaded.subscriberPageSize,
          offset: 0,
          search: searchQuery,
          coachId: selectedCoachId,
          branchId: selectedBranchId,
        ),
      ]);

      if (requestId != _requestId) return;

      final coaches = results[0] as List<CoachUserStats>;
      final branches = results[1] as List<Branch>;
      final page = results[2] as PagedResult<ActiveUser>;
      final users = _dedupe(page.items);
      _hasMoreFromServer = page.hasMore;

      emit(
        TrackingLoaded(
          coaches: coaches,
          branches: branches,
          users: users,
          selectedCoachId: selectedCoachId,
          selectedBranchId: selectedBranchId,
          searchQuery: searchQuery,
          hasMoreSubscribers: _hasMoreFromServer,
          totalCount: page.totalCount,
        ),
      );
      _hasLoadedOnce = true;
    } catch (e) {
      if (requestId != _requestId) return;
      if (event.silent && current is TrackingLoaded) {
        emit(current.copyWith(isRefreshing: false));
        return;
      }
      emit(TrackingError('Failed to load tracking data: $e'));
    }
  }

  Future<void> _onSearchUsers(
    SearchUsers event,
    Emitter<TrackingState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TrackingLoaded) return;

    final query = event.query.trim();
    if (query == (currentState.searchQuery ?? '')) return;

    emit(
      currentState.copyWith(
        searchQuery: query.isEmpty ? null : query,
        clearSearchQuery: query.isEmpty,
        isSearching: true,
        clearLoadMoreError: true,
      ),
    );

    await _reloadMembers(emit);
  }

  Future<void> _onLoadMoreSubscribers(
    LoadMoreSubscribers event,
    Emitter<TrackingState> emit,
  ) async {
    final current = state;
    if (current is! TrackingLoaded ||
        current.isLoadingMore ||
        current.isRefreshing ||
        !current.hasMoreSubscribers) {
      return;
    }

    if (!_hasMoreFromServer) return;

    final requestId = ++_requestId;
    emit(current.copyWith(isLoadingMore: true, clearLoadMoreError: true));

    try {
      final page = await repository.getMembers(
        limit: TrackingLoaded.subscriberPageSize,
        offset: current.users.length,
        search: current.searchQuery,
        coachId: current.selectedCoachId,
        branchId: current.selectedBranchId,
      );

      if (requestId != _requestId) return;

      _hasMoreFromServer = page.hasMore;
      final allUsers = _dedupe([...current.users, ...page.items]);

      emit(
        current.copyWith(
          users: allUsers,
          isLoadingMore: false,
          hasMoreSubscribers: _hasMoreFromServer,
          totalCount: page.totalCount ?? current.totalCount,
          clearLoadMoreError: true,
        ),
      );
    } catch (e) {
      if (requestId != _requestId) return;
      emit(
        current.copyWith(
          isLoadingMore: false,
          loadMoreError: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onFilterByCoach(
    FilterByCoach event,
    Emitter<TrackingState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TrackingLoaded) return;

    emit(
      currentState.copyWith(
        selectedCoachId: event.coachId,
        clearCoachFilter: event.coachId == null,
        isFiltering: true,
        clearLoadMoreError: true,
      ),
    );

    await _reloadMembers(emit);
  }

  Future<void> _onFilterByBranch(
    FilterByBranch event,
    Emitter<TrackingState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TrackingLoaded) return;

    List<CoachUserStats> latestCoaches = currentState.coaches;
    try {
      latestCoaches = await repository.getCoachUserStats();
    } catch (_) {
      latestCoaches = currentState.coaches;
    }

    emit(
      currentState.copyWith(
        coaches: latestCoaches,
        selectedCoachId: null,
        clearCoachFilter: true,
        selectedBranchId: event.branchId,
        clearBranchFilter: event.branchId == null,
        isFiltering: true,
        clearLoadMoreError: true,
      ),
    );

    await _reloadMembers(emit);
  }

  Future<void> _reloadMembers(Emitter<TrackingState> emit) async {
    final current = state;
    if (current is! TrackingLoaded) return;

    final requestId = ++_requestId;

    try {
      final page = await repository.getMembers(
        limit: TrackingLoaded.subscriberPageSize,
        offset: 0,
        search: current.searchQuery,
        coachId: current.selectedCoachId,
        branchId: current.selectedBranchId,
      );

      if (requestId != _requestId) return;

      _hasMoreFromServer = page.hasMore;

      emit(
        current.copyWith(
          users: _dedupe(page.items),
          isSearching: false,
          isFiltering: false,
          isRefreshing: false,
          hasMoreSubscribers: _hasMoreFromServer,
          totalCount: page.totalCount,
          clearLoadMoreError: true,
        ),
      );
    } catch (e) {
      if (requestId != _requestId) return;
      emit(
        current.copyWith(
          isSearching: false,
          isFiltering: false,
          isRefreshing: false,
          loadMoreError: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onLoadUserDetail(
    LoadUserDetail event,
    Emitter<TrackingState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TrackingLoaded) return;

    emit(
      UserDetailLoading(
        coaches: currentState.coaches,
        branches: currentState.branches,
        users: currentState.users,
        selectedCoachId: currentState.selectedCoachId,
        selectedBranchId: currentState.selectedBranchId,
        searchQuery: currentState.searchQuery,
        isSearching: currentState.isSearching,
        isFiltering: currentState.isFiltering,
        isRefreshing: currentState.isRefreshing,
        hasMoreSubscribers: currentState.hasMoreSubscribers,
        totalCount: currentState.totalCount,
      ),
    );

    try {
      final bookings = await repository.getUserBookingDetails(event.userId);

      final activeBookings =
          bookings.where((b) => b.isActive).toList(growable: false);
      final expiredBookings =
          bookings.where((b) => !b.isActive).toList(growable: false);

      final detailState = UserDetailLoaded(
        userId: event.userId,
        coaches: currentState.coaches,
        branches: currentState.branches,
        users: currentState.users,
        activeBookings: activeBookings,
        expiredBookings: expiredBookings,
        selectedCoachId: currentState.selectedCoachId,
        selectedBranchId: currentState.selectedBranchId,
        searchQuery: currentState.searchQuery,
        isSearching: currentState.isSearching,
        isFiltering: currentState.isFiltering,
        isRefreshing: currentState.isRefreshing,
        hasMoreSubscribers: currentState.hasMoreSubscribers,
        totalCount: currentState.totalCount,
      );

      emit(detailState);

      final firstBooking = activeBookings.isNotEmpty
          ? activeBookings.first
          : (bookings.isNotEmpty ? bookings.first : null);

      if (firstBooking != null) {
        add(
          LoadWeeklyAttendance(
            userId: event.userId,
            bookingId: firstBooking.bookingId,
          ),
        );
      }
    } catch (e) {
      emit(TrackingError('Failed to load user detail: $e'));
    }
  }

  Future<void> _onLoadWeeklyAttendance(
    LoadWeeklyAttendance event,
    Emitter<TrackingState> emit,
  ) async {
    final currentState = state;
    if (currentState is! UserDetailLoaded) return;

    emit(currentState.copyWithDetail(isLoadingAttendance: true));

    try {
      final days = await repository.getWeeklyAttendance(
        event.userId,
        event.bookingId,
      );

      emit(
        currentState.copyWithDetail(
          weeklyAttendance: days,
          selectedBookingId: event.bookingId,
          isLoadingAttendance: false,
        ),
      );
    } catch (e) {
      emit(currentState.copyWithDetail(isLoadingAttendance: false));
    }
  }

  List<ActiveUser> _dedupe(List<ActiveUser> users) {
    final seen = <String>{};
    final result = <ActiveUser>[];
    for (final user in users) {
      if (seen.add(user.userId)) result.add(user);
    }
    return result;
  }

  void _ensureRealtimeSubscription() {
    if (_trackingRealtimeChannel != null) return;

    final supabase = Supabase.instance.client;
    _trackingRealtimeChannel = supabase
        .channel('tracking-live-updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          callback: (_) => _scheduleRealtimeRefresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'attendance',
          callback: (_) => _scheduleRealtimeRefresh(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'payments',
          callback: (_) => _scheduleRealtimeRefresh(),
        )
        .subscribe((status, error) {
          if (status == RealtimeSubscribeStatus.channelError ||
              status == RealtimeSubscribeStatus.timedOut) {
            _trackingRealtimeChannel?.unsubscribe();
            _trackingRealtimeChannel = null;
            Future<void>.delayed(const Duration(seconds: 2), () {
              if (!isClosed) _ensureRealtimeSubscription();
            });
          }
        });
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (isClosed || !_hasLoadedOnce) return;
      if (state is TrackingLoaded) {
        repository.invalidateCaches();
        add(const LoadTrackingData(silent: true));
      }
    });
  }

  void _scheduleRealtimeRefresh() {
    _realtimeDebounce?.cancel();
    _realtimeDebounce = Timer(const Duration(milliseconds: 600), () {
      if (isClosed || !_hasLoadedOnce) return;
      repository.invalidateCaches();
      if (state is TrackingLoaded) {
        add(const LoadTrackingData(silent: true));
      } else if (state is TrackingError) {
        add(const LoadTrackingData());
      }
    });
  }

  @override
  Future<void> close() {
    _realtimeDebounce?.cancel();
    _pollTimer?.cancel();
    _trackingRealtimeChannel?.unsubscribe();
    _trackingRealtimeChannel = null;
    return super.close();
  }
}
