import 'package:equatable/equatable.dart';

abstract class TrackingEvent extends Equatable {
  const TrackingEvent();

  @override
  List<Object?> get props => [];
}

class LoadTrackingData extends TrackingEvent {
  final bool silent;

  const LoadTrackingData({this.silent = false});

  @override
  List<Object?> get props => [silent];
}

class LoadMoreSubscribers extends TrackingEvent {
  const LoadMoreSubscribers();
}

class SearchUsers extends TrackingEvent {
  final String query;

  const SearchUsers(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterByCoach extends TrackingEvent {
  final String? coachId;

  const FilterByCoach(this.coachId);

  @override
  List<Object?> get props => [coachId];
}

class FilterByBranch extends TrackingEvent {
  final String? branchId;

  const FilterByBranch(this.branchId);

  @override
  List<Object?> get props => [branchId];
}

class LoadUserDetail extends TrackingEvent {
  final String userId;

  const LoadUserDetail(this.userId);

  @override
  List<Object?> get props => [userId];
}

class LoadWeeklyAttendance extends TrackingEvent {
  final String userId;
  final String bookingId;

  const LoadWeeklyAttendance({
    required this.userId,
    required this.bookingId,
  });

  @override
  List<Object?> get props => [userId, bookingId];
}
