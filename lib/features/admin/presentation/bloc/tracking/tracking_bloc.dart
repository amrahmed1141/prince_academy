import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/features/admin/data/models/active_user_model.dart';
import 'package:prince_academy/features/admin/data/repositories/branch_repository.dart';
import 'package:prince_academy/features/admin/data/repositories/coach_repository.dart';
import 'package:prince_academy/features/admin/presentation/bloc/tracking/tracking_event.dart';
import 'package:prince_academy/features/admin/presentation/bloc/tracking/tracking_state.dart';

class TrackingBloc extends Bloc<TrackingEvent, TrackingState> {
  final CoachRepository repository;
  final BranchRepository branchRepository;

  Set<String> _coachUserIds = {};
  Set<String> _branchUserIds = {};

  TrackingBloc({
    required this.repository,
    required this.branchRepository,
  }) : super(const TrackingInitial()) {
    on<LoadTrackingData>(_onLoadTrackingData);
    on<SearchUsers>(_onSearchUsers);
    on<FilterByCoach>(_onFilterByCoach);
    on<FilterByBranch>(_onFilterByBranch);
    on<LoadUserDetail>(_onLoadUserDetail);
    on<LoadWeeklyAttendance>(_onLoadWeeklyAttendance);
  }

  Future<void> _onLoadTrackingData(
    LoadTrackingData event,
    Emitter<TrackingState> emit,
  ) async {
    emit(const TrackingLoading());

    try {
      final coaches = await repository.getCoachUserStats();
      final users = await repository.getActiveUsersWithQr();
      final branches = await branchRepository.getAllBranches();

      emit(
        TrackingLoaded(
          coaches: coaches,
          branches: branches,
          users: users,
          filteredUsers: users,
        ),
      );
    } catch (e) {
      emit(TrackingError('Failed to load tracking data: $e'));
    }
  }

  Future<void> _onSearchUsers(
    SearchUsers event,
    Emitter<TrackingState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TrackingLoaded) return;

    emit(currentState.copyWith(isSearching: true));

    try {
      final users = event.query.trim().isEmpty
          ? await _usersForFilters(
              currentState.selectedCoachId,
              currentState.selectedBranchId,
            )
          : await _searchUsersForFilters(
              event.query,
              currentState.selectedCoachId,
              currentState.selectedBranchId,
            );

      emit(
        currentState.copyWith(
          filteredUsers: users,
          searchQuery: event.query.trim().isEmpty ? null : event.query,
          clearSearchQuery: event.query.trim().isEmpty,
          isSearching: false,
        ),
      );
    } catch (e) {
      emit(currentState.copyWith(isSearching: false));
    }
  }

  Future<void> _onFilterByCoach(
    FilterByCoach event,
    Emitter<TrackingState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TrackingLoaded) return;

    emit(currentState.copyWith(isFiltering: true));

    try {
      final filteredUsers = await _usersForFilters(
        event.coachId,
        currentState.selectedBranchId,
      );
      final searched = _applyLocalSearch(
        filteredUsers,
        currentState.searchQuery,
      );

      emit(
        currentState.copyWith(
          filteredUsers: searched,
          selectedCoachId: event.coachId,
          clearCoachFilter: event.coachId == null,
          isFiltering: false,
        ),
      );
    } catch (e) {
      emit(currentState.copyWith(isFiltering: false));
    }
  }

  Future<void> _onFilterByBranch(
    FilterByBranch event,
    Emitter<TrackingState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TrackingLoaded) return;

    emit(currentState.copyWith(isFiltering: true));

    try {
      final filteredUsers = await _usersForFilters(
        currentState.selectedCoachId,
        event.branchId,
      );
      final searched = _applyLocalSearch(
        filteredUsers,
        currentState.searchQuery,
      );

      emit(
        currentState.copyWith(
          filteredUsers: searched,
          selectedBranchId: event.branchId,
          clearBranchFilter: event.branchId == null,
          isFiltering: false,
        ),
      );
    } catch (e) {
      emit(currentState.copyWith(isFiltering: false));
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
        filteredUsers: currentState.filteredUsers,
        selectedCoachId: currentState.selectedCoachId,
        selectedBranchId: currentState.selectedBranchId,
        searchQuery: currentState.searchQuery,
        isSearching: currentState.isSearching,
        isFiltering: currentState.isFiltering,
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

  Future<List<ActiveUser>> _usersForFilters(
    String? coachId,
    String? branchId,
  ) async {
    var users = await repository.getActiveUsersWithQr();

    if (coachId != null) {
      _coachUserIds = await repository.getUserIdsForCoach(coachId);
      users = users.where((user) => _coachUserIds.contains(user.userId)).toList();
    } else {
      _coachUserIds = {};
    }

    if (branchId != null) {
      _branchUserIds = await repository.getUserIdsForBranch(branchId);
      users = users.where((user) => _branchUserIds.contains(user.userId)).toList();
    } else {
      _branchUserIds = {};
    }

    return users;
  }

  Future<List<ActiveUser>> _searchUsersForFilters(
    String query,
    String? coachId,
    String? branchId,
  ) async {
    var results = await repository.searchActiveUsers(query);

    if (coachId != null) {
      if (_coachUserIds.isEmpty) {
        _coachUserIds = await repository.getUserIdsForCoach(coachId);
      }
      results = results
          .where((user) => _coachUserIds.contains(user.userId))
          .toList();
    }

    if (branchId != null) {
      if (_branchUserIds.isEmpty) {
        _branchUserIds = await repository.getUserIdsForBranch(branchId);
      }
      results = results
          .where((user) => _branchUserIds.contains(user.userId))
          .toList();
    }

    return results;
  }

  List<ActiveUser> _applyLocalSearch(
    List<ActiveUser> users,
    String? query,
  ) {
    final trimmed = query?.trim().toLowerCase() ?? '';
    if (trimmed.isEmpty) return users;

    return users
        .where((user) {
          final name = user.fullName.toLowerCase();
          final phone = user.phone?.toLowerCase() ?? '';
          return name.contains(trimmed) || phone.contains(trimmed);
        })
        .toList();
  }
}
