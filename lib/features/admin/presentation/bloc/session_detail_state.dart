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
  final bool isReAttending;
  final bool isUnmarking;
  final String? reAttendMessage;

  const SessionDetailLoaded({
    required this.bookingId,
    required this.completed,
    required this.upcoming,
    required this.missed,
    required this.totalSessions,
    required this.completedCount,
    required this.remainingCount,
    this.isReAttending = false,
    this.isUnmarking = false,
    this.reAttendMessage,
  });

  SessionDetailLoaded copyWith({
    List<SessionDetail>? completed,
    List<SessionDetail>? upcoming,
    List<SessionDetail>? missed,
    int? totalSessions,
    int? completedCount,
    int? remainingCount,
    bool? isReAttending,
    bool? isUnmarking,
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
      isReAttending: isReAttending ?? this.isReAttending,
      isUnmarking: isUnmarking ?? this.isUnmarking,
      reAttendMessage:
          clearReAttendMessage ? null : reAttendMessage ?? this.reAttendMessage,
    );
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
        isReAttending,
        isUnmarking,
        reAttendMessage,
      ];
}

class SessionDetailError extends SessionDetailState {
  final String message;

  const SessionDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
