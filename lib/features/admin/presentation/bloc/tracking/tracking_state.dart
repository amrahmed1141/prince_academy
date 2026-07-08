import 'package:equatable/equatable.dart';
import 'package:prince_academy/features/admin/data/models/active_user_model.dart';
import 'package:prince_academy/features/admin/data/models/branch_model.dart';
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
  final List<Branch> branches;
  final List<ActiveUser> users;
  final List<ActiveUser> filteredUsers;
  final String? selectedCoachId;
  final String? selectedBranchId;
  final String? searchQuery;
  final bool isSearching;
  final bool isFiltering;
  final bool isRefreshing;
  final int visibleSubscriberCount;
  final bool hasMoreSubscribers;
  final bool isLoadingMore;

  static const int subscriberPageSize = 50;

  const TrackingLoaded({
    required this.coaches,
    this.branches = const [],
    required this.users,
    required this.filteredUsers,
    this.selectedCoachId,
    this.selectedBranchId,
    this.searchQuery,
    this.isSearching = false,
    this.isFiltering = false,
    this.isRefreshing = false,
    this.visibleSubscriberCount = subscriberPageSize,
    this.hasMoreSubscribers = false,
    this.isLoadingMore = false,
  });

  List<ActiveUser> get visibleUsers => filteredUsers.length <= visibleSubscriberCount
      ? filteredUsers
      : filteredUsers.sublist(0, visibleSubscriberCount);

  List<CoachUserStats> get displayCoaches {
    if (selectedBranchId == null) return coaches;
    final direct = coaches
        .where((coach) => _normalize(coach.branchId) == _normalize(selectedBranchId))
        .toList();
    if (direct.isNotEmpty) return direct;

    Branch? selectedBranch;
    for (final branch in branches) {
      if (branch.id == selectedBranchId) {
        selectedBranch = branch;
        break;
      }
    }
    final selectedName = _normalize(selectedBranch?.name);
    if (selectedName.isEmpty) return direct;

    return coaches
        .where((coach) => _normalize(coach.branchName) == selectedName)
        .toList();
  }

  String _normalize(String? value) => (value ?? '').trim().toLowerCase();

  String? get selectedCoachName {
    if (selectedCoachId == null) return null;
    for (final coach in coaches) {
      if (coach.coachId == selectedCoachId) return coach.coachName;
    }
    return null;
  }

  String? get selectedBranchName {
    if (selectedBranchId == null) return null;
    for (final branch in branches) {
      if (branch.id == selectedBranchId) return branch.name;
    }
    return null;
  }

  TrackingLoaded copyWith({
    List<CoachUserStats>? coaches,
    List<Branch>? branches,
    List<ActiveUser>? users,
    List<ActiveUser>? filteredUsers,
    String? selectedCoachId,
    bool clearCoachFilter = false,
    String? selectedBranchId,
    bool clearBranchFilter = false,
    String? searchQuery,
    bool clearSearchQuery = false,
    bool? isSearching,
    bool? isFiltering,
    bool? isRefreshing,
    int? visibleSubscriberCount,
    bool? hasMoreSubscribers,
    bool? isLoadingMore,
    bool resetPagination = false,
  }) {
    final nextFiltered = filteredUsers ?? this.filteredUsers;
    final nextVisible = resetPagination
        ? subscriberPageSize
        : visibleSubscriberCount ?? this.visibleSubscriberCount;
    final nextHasMore = hasMoreSubscribers ??
        (nextFiltered.length > nextVisible);

    return TrackingLoaded(
      coaches: coaches ?? this.coaches,
      branches: branches ?? this.branches,
      users: users ?? this.users,
      filteredUsers: nextFiltered,
      selectedCoachId:
          clearCoachFilter ? null : selectedCoachId ?? this.selectedCoachId,
      selectedBranchId:
          clearBranchFilter ? null : selectedBranchId ?? this.selectedBranchId,
      searchQuery: clearSearchQuery ? null : searchQuery ?? this.searchQuery,
      isSearching: isSearching ?? this.isSearching,
      isFiltering: isFiltering ?? this.isFiltering,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      visibleSubscriberCount: nextVisible,
      hasMoreSubscribers: nextHasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
        coaches,
        branches,
        users,
        filteredUsers,
        selectedCoachId,
        selectedBranchId,
        searchQuery,
        isSearching,
        isFiltering,
        isRefreshing,
        visibleSubscriberCount,
        hasMoreSubscribers,
        isLoadingMore,
      ];
}

class UserDetailLoading extends TrackingLoaded {
  const UserDetailLoading({
    required super.coaches,
    super.branches,
    required super.users,
    required super.filteredUsers,
    super.selectedCoachId,
    super.selectedBranchId,
    super.searchQuery,
    super.isSearching,
    super.isFiltering,
    super.isRefreshing,
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
    super.branches,
    required super.users,
    required super.filteredUsers,
    required this.activeBookings,
    required this.expiredBookings,
    this.weeklyAttendance = const [],
    this.selectedBookingId,
    this.isLoadingAttendance = false,
    super.selectedCoachId,
    super.selectedBranchId,
    super.searchQuery,
    super.isSearching,
    super.isFiltering,
    super.isRefreshing,
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
      selectedBranchId: selectedBranchId,
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
