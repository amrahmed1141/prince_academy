import 'package:equatable/equatable.dart';
import 'package:prince_academy/features/admin/data/models/coach_model.dart';
import 'package:prince_academy/features/home/data/models/coach_session_model.dart';

enum AdminHomeMessageType { success, error, delete }

class AdminHomeState extends Equatable {
  final List<CoachModel> coaches;
  final List<CoachSessionModel> sessions;
  final bool isLoadingCoaches;
  final bool isLoadingSessions;
  final bool isAddingCoach;
  final bool isSavingSession;
  final String? sessionsError;
  final String? message;
  final AdminHomeMessageType? messageType;

  const AdminHomeState({
    this.coaches = const [],
    this.sessions = const [],
    this.isLoadingCoaches = false,
    this.isLoadingSessions = false,
    this.isAddingCoach = false,
    this.isSavingSession = false,
    this.sessionsError,
    this.message,
    this.messageType,
  });

  AdminHomeState copyWith({
    List<CoachModel>? coaches,
    List<CoachSessionModel>? sessions,
    bool? isLoadingCoaches,
    bool? isLoadingSessions,
    bool? isAddingCoach,
    bool? isSavingSession,
    String? sessionsError,
    bool clearSessionsError = false,
    String? message,
    AdminHomeMessageType? messageType,
    bool clearMessage = false,
  }) {
    return AdminHomeState(
      coaches: coaches ?? this.coaches,
      sessions: sessions ?? this.sessions,
      isLoadingCoaches: isLoadingCoaches ?? this.isLoadingCoaches,
      isLoadingSessions: isLoadingSessions ?? this.isLoadingSessions,
      isAddingCoach: isAddingCoach ?? this.isAddingCoach,
      isSavingSession: isSavingSession ?? this.isSavingSession,
      sessionsError:
          clearSessionsError ? null : sessionsError ?? this.sessionsError,
      message: clearMessage ? null : message ?? this.message,
      messageType: clearMessage ? null : messageType ?? this.messageType,
    );
  }

  @override
  List<Object?> get props => [
        coaches,
        sessions,
        isLoadingCoaches,
        isLoadingSessions,
        isAddingCoach,
        isSavingSession,
        sessionsError,
        message,
        messageType,
      ];
}
