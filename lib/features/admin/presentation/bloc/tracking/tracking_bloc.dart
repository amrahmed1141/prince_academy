import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prince_academy/features/admin/data/models/active_user_model.dart';
import 'package:prince_academy/features/admin/data/models/coach_user_stats_model.dart';
import 'package:prince_academy/features/admin/data/repositories/branch_repository.dart';
import 'package:prince_academy/features/admin/data/repositories/coach_repository.dart';
import 'package:prince_academy/features/admin/presentation/bloc/tracking/tracking_event.dart';
import 'package:prince_academy/features/admin/presentation/bloc/tracking/tracking_state.dart';

class TrackingBloc extends Bloc<TrackingEvent, TrackingState> {
  final CoachRepository repository;
  final BranchRepository branchRepository;

  final Map<String, Set<String>> _coachUserIdsCache = {};
  final Map<String, Set<String>> _branchUserIdsCache = {};
  int _serverPage = 0;
  bool _hasMoreFromServer = true;
  RealtimeChannel? _trackingRealtimeChannel;
  Timer? _realtimeDebounce;

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
    final previousVisibleCount = currentLoaded?.visibleSubscriberCount ??
        TrackingLoaded.subscriberPageSize;

    if (event.silent && current is TrackingLoaded) {
      emit(current.copyWith(isRefreshing: true));
    } else {
      emit(const TrackingLoading());
    }

    try {
      final coaches = await repository.getCoachUserStats();
      final branches = await branchRepository.getAllBranches();
      _serverPage = 0;
      _hasMoreFromServer = true;
      _coachUserIdsCache.clear();
      _branchUserIdsCache.clear();

      final users = await repository.getActiveUsersWithQr(
        force: true,
        limit: TrackingLoaded.subscriberPageSize,
        offset: 0,
      );
      _hasMoreFromServer = users.length >= TrackingLoaded.subscriberPageSize;

      final pendingIds = await repository.getUserIdsWithPendingPayments();
      final usersWithPending = users
          .map((u) => u.copyWith(
                hasPendingPayment: pendingIds.contains(u.userId),
              ))
          .toList();

      final filtered = await _filterUsers(
        usersWithPending,
        coachId: selectedCoachId,
        branchId: selectedBranchId,
        query: searchQuery,
      );

      final visibleCount = filtered.isEmpty
          ? TrackingLoaded.subscriberPageSize
          : (filtered.length < TrackingLoaded.subscriberPageSize
              ? filtered.length
              : previousVisibleCount.clamp(
                  TrackingLoaded.subscriberPageSize,
                  filtered.length,
                ));
      emit(
        TrackingLoaded(
          coaches: coaches,
          branches: branches,
          users: users,
          filteredUsers: filtered,
          selectedCoachId: selectedCoachId,
          selectedBranchId: selectedBranchId,
          searchQuery: searchQuery,
          visibleSubscriberCount: visibleCount,
          hasMoreSubscribers:
              filtered.length > visibleCount ||
                  _hasMoreFromServer,
        ),
      );
    } catch (e) {
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
    final filtered = await _filterUsers(
      currentState.users,
      coachId: currentState.selectedCoachId,
      branchId: currentState.selectedBranchId,
      query: query.isEmpty ? null : query,
    );

    emit(
      currentState.copyWith(
        filteredUsers: filtered,
        searchQuery: query.isEmpty ? null : query,
        clearSearchQuery: query.isEmpty,
        isSearching: false,
        resetPagination: true,
        hasMoreSubscribers:
            filtered.length > TrackingLoaded.subscriberPageSize ||
                _hasMoreFromServer,
      ),
    );
  }

  Future<void> _onLoadMoreSubscribers(
    LoadMoreSubscribers event,
    Emitter<TrackingState> emit,
  ) async {
    final current = state;
    if (current is! TrackingLoaded ||
        current.isLoadingMore ||
        !current.hasMoreSubscribers) {
      return;
    }

    if (current.visibleSubscriberCount < current.filteredUsers.length) {
      final nextVisible =
          current.visibleSubscriberCount + TrackingLoaded.subscriberPageSize;
      emit(
        current.copyWith(
          visibleSubscriberCount: nextVisible,
          hasMoreSubscribers:
              current.filteredUsers.length > nextVisible || _hasMoreFromServer,
        ),
      );
      return;
    }

    if (!_hasMoreFromServer) return;

    emit(current.copyWith(isLoadingMore: true));

    try {
      _serverPage++;
      final offset = _serverPage * TrackingLoaded.subscriberPageSize;
      final nextPage = await repository.getActiveUsersWithQr(
        force: true,
        limit: TrackingLoaded.subscriberPageSize,
        offset: offset,
      );
      _hasMoreFromServer =
          nextPage.length >= TrackingLoaded.subscriberPageSize;

      final pendingIds = await repository.getUserIdsWithPendingPayments();
      final allUsers = [...current.users, ...nextPage].map((u) {
        if (u.hasPendingPayment == pendingIds.contains(u.userId)) return u;
        return u.copyWith(hasPendingPayment: pendingIds.contains(u.userId));
      }).toList();
      final filtered = await _filterUsers(
        allUsers,
        coachId: current.selectedCoachId,
        branchId: current.selectedBranchId,
        query: current.searchQuery,
      );
      final nextVisible =
          current.visibleSubscriberCount + TrackingLoaded.subscriberPageSize;

      emit(
        current.copyWith(
          users: allUsers,
          filteredUsers: filtered,
          visibleSubscriberCount: nextVisible,
          isLoadingMore: false,
          hasMoreSubscribers:
              filtered.length > nextVisible || _hasMoreFromServer,
        ),
      );
    } catch (_) {
      emit(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onFilterByCoach(
    FilterByCoach event,
    Emitter<TrackingState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TrackingLoaded) return;

    final filtered = await _filterUsers(
      currentState.users,
      coachId: event.coachId,
      branchId: currentState.selectedBranchId,
      query: currentState.searchQuery,
    );

    emit(
      currentState.copyWith(
        filteredUsers: filtered,
        selectedCoachId: event.coachId,
        clearCoachFilter: event.coachId == null,
        isFiltering: false,
        resetPagination: true,
        hasMoreSubscribers:
            filtered.length > TrackingLoaded.subscriberPageSize ||
                _hasMoreFromServer,
      ),
    );
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

    final filtered = await _filterUsers(
      currentState.users,
      coachId: currentState.selectedCoachId,
      branchId: event.branchId,
      query: currentState.searchQuery,
    );

    emit(
      currentState.copyWith(
        coaches: latestCoaches,
        filteredUsers: filtered,
        selectedCoachId: null,
        clearCoachFilter: true,
        selectedBranchId: event.branchId,
        clearBranchFilter: event.branchId == null,
        isFiltering: false,
        resetPagination: true,
        hasMoreSubscribers:
            filtered.length > TrackingLoaded.subscriberPageSize ||
                _hasMoreFromServer,
      ),
    );
  }

  Future<List<ActiveUser>> _filterUsers(
    List<ActiveUser> users, {
    String? coachId,
    String? branchId,
    String? query,
  }) async {
    var result = users;

    if (coachId != null) {
      final ids = await _coachUserIds(coachId);
      result = result.where((u) => ids.contains(u.userId)).toList();
    }

    if (branchId != null) {
      final ids = await _branchUserIds(branchId);
      result = result.where((u) => ids.contains(u.userId)).toList();
    }

    return _applyLocalSearch(result, query);
  }

  Future<Set<String>> _coachUserIds(String coachId) async {
    if (_coachUserIdsCache.containsKey(coachId)) {
      return _coachUserIdsCache[coachId]!;
    }
    final ids = await repository.getUserIdsForCoach(coachId);
    _coachUserIdsCache[coachId] = ids;
    return ids;
  }

  Future<Set<String>> _branchUserIds(String branchId) async {
    if (_branchUserIdsCache.containsKey(branchId)) {
      return _branchUserIdsCache[branchId]!;
    }
    final ids = await repository.getUserIdsForBranch(branchId);
    _branchUserIdsCache[branchId] = ids;
    return ids;
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
        filteredUsers: currentState.filteredUsers,
        selectedCoachId: currentState.selectedCoachId,
        selectedBranchId: currentState.selectedBranchId,
        searchQuery: currentState.searchQuery,
        isSearching: currentState.isSearching,
        isFiltering: currentState.isFiltering,
        isRefreshing: currentState.isRefreshing,
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
        filteredUsers: currentState.filteredUsers,
        activeBookings: activeBookings,
        expiredBookings: expiredBookings,
        selectedCoachId: currentState.selectedCoachId,
        selectedBranchId: currentState.selectedBranchId,
        searchQuery: currentState.searchQuery,
        isSearching: currentState.isSearching,
        isFiltering: currentState.isFiltering,
        isRefreshing: currentState.isRefreshing,
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

  List<ActiveUser> _applyLocalSearch(
    List<ActiveUser> users,
    String? query,
  ) {
    final trimmed = query?.trim().toLowerCase() ?? '';
    var result = users;

    if (trimmed.isNotEmpty) {
      result = result
          .where((user) {
            final name = user.fullName.toLowerCase();
            final phone = user.phone?.toLowerCase() ?? '';
            return name.contains(trimmed) || phone.contains(trimmed);
          })
          .toList();
    }

    result.sort((a, b) {
      if (a.hasPendingPayment && !b.hasPendingPayment) return -1;
      if (!a.hasPendingPayment && b.hasPendingPayment) return 1;
      return a.fullName.compareTo(b.fullName);
    });

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
        .subscribe();
  }

  void _scheduleRealtimeRefresh() {
    _realtimeDebounce?.cancel();
    _realtimeDebounce = Timer(const Duration(milliseconds: 700), () {
      if (isClosed) return;
      if (state is TrackingLoaded) {
        add(const LoadTrackingData(silent: true));
      }
    });
  }

  @override
  Future<void> close() {
    _realtimeDebounce?.cancel();
    _trackingRealtimeChannel?.unsubscribe();
    _trackingRealtimeChannel = null;
    return super.close();
  }
}
