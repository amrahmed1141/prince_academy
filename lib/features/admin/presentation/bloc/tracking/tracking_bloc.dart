import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/features/admin/data/models/active_user_model.dart';
import 'package:prince_academy/features/admin/data/repositories/coach_repository.dart';
import 'package:prince_academy/features/admin/presentation/bloc/tracking/tracking_event.dart';
import 'package:prince_academy/features/admin/presentation/bloc/tracking/tracking_state.dart';

class TrackingBloc extends Bloc<TrackingEvent, TrackingState> {
  final CoachRepository repository;

  Set<String> _coachUserIds = {};

  TrackingBloc({required this.repository}) : super(const TrackingInitial()) {
    on<LoadTrackingData>(_onLoadTrackingData);
    on<SearchUsers>(_onSearchUsers);
    on<FilterByCoach>(_onFilterByCoach);
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

      emit(
        TrackingLoaded(
          coaches: coaches,
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
          ? await _usersForCoach(currentState.selectedCoachId)
          : await _searchUsersForCoach(
              event.query,
              currentState.selectedCoachId,
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
      final filteredUsers = await _usersForCoach(event.coachId);
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

  Future<void> _onLoadUserDetail(
    LoadUserDetail event,
    Emitter<TrackingState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TrackingLoaded) return;

    emit(
      UserDetailLoading(
        coaches: currentState.coaches,
        users: currentState.users,
        filteredUsers: currentState.filteredUsers,
        selectedCoachId: currentState.selectedCoachId,
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
        users: currentState.users,
        filteredUsers: currentState.filteredUsers,
        activeBookings: activeBookings,
        expiredBookings: expiredBookings,
        selectedCoachId: currentState.selectedCoachId,
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

  Future<List<ActiveUser>> _usersForCoach(String? coachId) async {
    final allUsers = await repository.getActiveUsersWithQr();

    if (coachId == null) {
      _coachUserIds = {};
      return allUsers;
    }

    _coachUserIds = await repository.getUserIdsForCoach(coachId);
    return allUsers
        .where((user) => _coachUserIds.contains(user.userId))
        .toList();
  }

  Future<List<ActiveUser>> _searchUsersForCoach(
    String query,
    String? coachId,
  ) async {
    final results = await repository.searchActiveUsers(query);
    if (coachId == null) return results;

    if (_coachUserIds.isEmpty) {
      _coachUserIds = await repository.getUserIdsForCoach(coachId);
    }

    return results
        .where((user) => _coachUserIds.contains(user.userId))
        .toList();
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
