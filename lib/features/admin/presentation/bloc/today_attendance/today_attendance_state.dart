import 'package:equatable/equatable.dart';
import 'package:prince_academy/features/admin/data/models/today_attendance_member_model.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_coach_booking_filter_chips.dart';

class TodayAttendanceState extends Equatable {
  const TodayAttendanceState({
    this.members = const [],
    this.coaches = const [],
    this.selectedCoachId,
    this.searchQuery = '',
    this.kpiAttended = 0,
    this.kpiBooked = 0,
    this.isLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.markingBookingIds = const {},
    this.error,
    this.loadMoreError,
    this.actionError,
  });

  static const int pageSize = 50;

  final List<TodayAttendanceMember> members;
  final List<AdminCoachBookingOption> coaches;
  final String? selectedCoachId;
  final String searchQuery;
  final int kpiAttended;
  final int kpiBooked;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMore;
  final Set<String> markingBookingIds;
  final String? error;
  final String? loadMoreError;
  final String? actionError;

  int get bookedTotal => kpiBooked;

  int get attendedTotal => kpiAttended;

  List<TodayAttendanceMember> get visibleMembers => members;

  List<AdminCoachBookingOption> get coachOptions => coaches;

  TodayAttendanceState copyWith({
    List<TodayAttendanceMember>? members,
    List<AdminCoachBookingOption>? coaches,
    String? selectedCoachId,
    bool clearSelectedCoach = false,
    String? searchQuery,
    int? kpiAttended,
    int? kpiBooked,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasMore,
    Set<String>? markingBookingIds,
    String? error,
    bool clearError = false,
    String? loadMoreError,
    bool clearLoadMoreError = false,
    String? actionError,
    bool clearActionError = false,
  }) {
    return TodayAttendanceState(
      members: members ?? this.members,
      coaches: coaches ?? this.coaches,
      selectedCoachId:
          clearSelectedCoach ? null : selectedCoachId ?? this.selectedCoachId,
      searchQuery: searchQuery ?? this.searchQuery,
      kpiAttended: kpiAttended ?? this.kpiAttended,
      kpiBooked: kpiBooked ?? this.kpiBooked,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      markingBookingIds: markingBookingIds ?? this.markingBookingIds,
      error: clearError ? null : error ?? this.error,
      loadMoreError:
          clearLoadMoreError ? null : loadMoreError ?? this.loadMoreError,
      actionError: clearActionError ? null : actionError ?? this.actionError,
    );
  }

  @override
  List<Object?> get props => [
        members,
        coaches,
        selectedCoachId,
        searchQuery,
        kpiAttended,
        kpiBooked,
        isLoading,
        isRefreshing,
        isLoadingMore,
        hasMore,
        markingBookingIds,
        error,
        loadMoreError,
        actionError,
      ];
}
