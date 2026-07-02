import 'package:equatable/equatable.dart';
import 'package:prince_academy/features/admin/data/models/session_detail_model.dart';

abstract class SessionDetailState extends Equatable {
  const SessionDetailState();

  @override
  List<Object?> get props => [];
}

class SessionDetailInitial extends SessionDetailState {
  const SessionDetailInitial();
}

class SessionDetailLoading extends SessionDetailState {
  const SessionDetailLoading();
}

class SessionDetailLoaded extends SessionDetailState {
  final String bookingId;
  final List<SessionDetail> completed;
  final List<SessionDetail> upcoming;
  final List<SessionDetail> missed;
  final int totalSessions;
  final int completedCount;
  final int remainingCount;
  final DateTime? pendingReAttendDate;
  final DateTime? pendingUnmarkDate;
  final String? reAttendMessage;

  const SessionDetailLoaded({
    required this.bookingId,
    required this.completed,
    required this.upcoming,
    required this.missed,
    required this.totalSessions,
    required this.completedCount,
    required this.remainingCount,
    this.pendingReAttendDate,
    this.pendingUnmarkDate,
    this.reAttendMessage,
  });

  SessionDetailLoaded copyWith({
    List<SessionDetail>? completed,
    List<SessionDetail>? upcoming,
    List<SessionDetail>? missed,
    int? totalSessions,
    int? completedCount,
    int? remainingCount,
    DateTime? pendingReAttendDate,
    DateTime? pendingUnmarkDate,
    bool clearPendingReAttend = false,
    bool clearPendingUnmark = false,
    String? reAttendMessage,
    bool clearReAttendMessage = false,
  }) {
    return SessionDetailLoaded(
      bookingId: bookingId,
      completed: completed ?? this.completed,
      upcoming: upcoming ?? this.upcoming,
      missed: missed ?? this.missed,
      totalSessions: totalSessions ?? this.totalSessions,
      completedCount: completedCount ?? this.completedCount,
      remainingCount: remainingCount ?? this.remainingCount,
      pendingReAttendDate: clearPendingReAttend
          ? null
          : pendingReAttendDate ?? this.pendingReAttendDate,
      pendingUnmarkDate:
          clearPendingUnmark ? null : pendingUnmarkDate ?? this.pendingUnmarkDate,
      reAttendMessage:
          clearReAttendMessage ? null : reAttendMessage ?? this.reAttendMessage,
    );
  }

  bool isReAttending(DateTime date) =>
      pendingReAttendDate != null && _isSameDay(pendingReAttendDate!, date);

  bool isUnmarking(DateTime date) =>
      pendingUnmarkDate != null && _isSameDay(pendingUnmarkDate!, date);

  static bool _isSameDay(DateTime a, DateTime b) {
    final al = a.toLocal();
    final bl = b.toLocal();
    return al.year == bl.year && al.month == bl.month && al.day == bl.day;
  }

  @override
  List<Object?> get props => [
        bookingId,
        completed,
        upcoming,
        missed,
        totalSessions,
        completedCount,
        remainingCount,
        pendingReAttendDate,
        pendingUnmarkDate,
        reAttendMessage,
      ];
}

class SessionDetailError extends SessionDetailState {
  final String message;

  const SessionDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
