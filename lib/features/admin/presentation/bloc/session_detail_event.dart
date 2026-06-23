import 'package:equatable/equatable.dart';

abstract class SessionDetailEvent extends Equatable {
  const SessionDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadSessionDetail extends SessionDetailEvent {
  final String bookingId;

  const LoadSessionDetail(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

class ReAttendSession extends SessionDetailEvent {
  final String bookingId;
  final DateTime sessionDate;

  const ReAttendSession({
    required this.bookingId,
    required this.sessionDate,
  });

  @override
  List<Object?> get props => [bookingId, sessionDate];
}

class UnmarkSession extends SessionDetailEvent {
  final String bookingId;
  final DateTime sessionDate;

  const UnmarkSession({
    required this.bookingId,
    required this.sessionDate,
  });

  @override
  List<Object?> get props => [bookingId, sessionDate];
}
