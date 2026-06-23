import 'package:equatable/equatable.dart';
import 'package:prince_academy/features/admin/data/models/active_user_model.dart';
import 'package:prince_academy/features/admin/data/models/coach_user_stats_model.dart';
import 'package:prince_academy/features/admin/data/models/day_attendance_model.dart';
import 'package:prince_academy/features/admin/data/models/user_booking_detail_model.dart';

abstract class TrackingState extends Equatable {
  const TrackingState();

  @override
  List<Object?> get props => [];
}

class TrackingInitial extends TrackingState {
  const TrackingInitial();
}

class TrackingLoading extends TrackingState {
  const TrackingLoading();
}

class TrackingLoaded extends TrackingState {
  final List<CoachUserStats> coaches;
  final List<ActiveUser> users;
  final List<ActiveUser> filteredUsers;
  final String? selectedCoachId;
  final String? searchQuery;
  final bool isSearching;
  final bool isFiltering;

  const TrackingLoaded({
    required this.coaches,
    required this.users,
    required this.filteredUsers,
    this.selectedCoachId,
    this.searchQuery,
    this.isSearching = false,
    this.isFiltering = false,
  });

  String? get selectedCoachName {
    if (selectedCoachId == null) return null;
    for (final coach in coaches) {
      if (coach.coachId == selectedCoachId) return coach.coachName;
    }
    return null;
  }

  TrackingLoaded copyWith({
    List<CoachUserStats>? coaches,
    List<ActiveUser>? users,
    List<ActiveUser>? filteredUsers,
    String? selectedCoachId,
    bool clearCoachFilter = false,
    String? searchQuery,
    bool clearSearchQuery = false,
    bool? isSearching,
    bool? isFiltering,
  }) {
    return TrackingLoaded(
      coaches: coaches ?? this.coaches,
      users: users ?? this.users,
      filteredUsers: filteredUsers ?? this.filteredUsers,
      selectedCoachId:
          clearCoachFilter ? null : selectedCoachId ?? this.selectedCoachId,
      searchQuery: clearSearchQuery ? null : searchQuery ?? this.searchQuery,
      isSearching: isSearching ?? this.isSearching,
      isFiltering: isFiltering ?? this.isFiltering,
    );
  }

  @override
  List<Object?> get props => [
        coaches,
        users,
        filteredUsers,
        selectedCoachId,
        searchQuery,
        isSearching,
        isFiltering,
      ];
}

class UserDetailLoading extends TrackingLoaded {
  const UserDetailLoading({
    required super.coaches,
    required super.users,
    required super.filteredUsers,
    super.selectedCoachId,
    super.searchQuery,
    super.isSearching,
    super.isFiltering,
  });
}

class UserDetailLoaded extends TrackingLoaded {
  final String userId;
  final List<UserBookingDetail> activeBookings;
  final List<UserBookingDetail> expiredBookings;
  final List<DayAttendance> weeklyAttendance;
  final String? selectedBookingId;
  final bool isLoadingAttendance;

  const UserDetailLoaded({
    required this.userId,
    required super.coaches,
    required super.users,
    required super.filteredUsers,
    required this.activeBookings,
    required this.expiredBookings,
    this.weeklyAttendance = const [],
    this.selectedBookingId,
    this.isLoadingAttendance = false,
    super.selectedCoachId,
    super.searchQuery,
    super.isSearching,
    super.isFiltering,
  });

  UserDetailLoaded copyWithDetail({
    List<UserBookingDetail>? activeBookings,
    List<UserBookingDetail>? expiredBookings,
    List<DayAttendance>? weeklyAttendance,
    String? selectedBookingId,
    bool? isLoadingAttendance,
  }) {
    return UserDetailLoaded(
      userId: userId,
      coaches: coaches,
      users: users,
      filteredUsers: filteredUsers,
      activeBookings: activeBookings ?? this.activeBookings,
      expiredBookings: expiredBookings ?? this.expiredBookings,
      weeklyAttendance: weeklyAttendance ?? this.weeklyAttendance,
      selectedBookingId: selectedBookingId ?? this.selectedBookingId,
      isLoadingAttendance: isLoadingAttendance ?? this.isLoadingAttendance,
      selectedCoachId: selectedCoachId,
      searchQuery: searchQuery,
      isSearching: isSearching,
      isFiltering: isFiltering,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        activeBookings,
        expiredBookings,
        weeklyAttendance,
        selectedBookingId,
        isLoadingAttendance,
        ...super.props,
      ];
}

class TrackingError extends TrackingState {
  final String message;

  const TrackingError(this.message);

  @override
  List<Object?> get props => [message];
}
