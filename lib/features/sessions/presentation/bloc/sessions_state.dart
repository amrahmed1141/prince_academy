import 'package:equatable/equatable.dart';
import 'package:prince_academy/features/booking/data/models/booking_history_model.dart';
import 'package:prince_academy/features/sessions/data/models/coach_summary_model.dart';
import 'package:prince_academy/features/sessions/data/models/session_model.dart';
import 'package:prince_academy/features/sessions/domain/weekly_progress_summary.dart';
import 'package:prince_academy/features/sessions/presentation/bloc/sessions_event.dart';

abstract class SessionsState extends Equatable {
  const SessionsState();

  @override
  List<Object?> get props => [];
}

class SessionsInitial extends SessionsState {}

class SessionsLoading extends SessionsState {}

class SessionsLoaded extends SessionsState {
  final List<CoachSummary> coaches;
  final List<BookingHistoryModel> bookings;
  final List<Session> allSessions;
  final List<Session> upcomingSessions;
  final List<Session> historySessions;
  final List<Session> filteredSessions;
  final DateTime selectedDate;
  final CoachSummary? selectedCoach;
  final SessionTab activeTab;
  final int totalSessions;
  final int attendedSessions;
  final int remainingSessions;
  final Session? nextSession;
  final bool showCoachFilter;
  final bool isLoading;
  final WeeklyProgressSummary weeklyProgress;

  const SessionsLoaded({
    required this.coaches,
    required this.bookings,
    required this.allSessions,
    required this.upcomingSessions,
    required this.historySessions,
    required this.filteredSessions,
    required this.selectedDate,
    this.selectedCoach,
    required this.activeTab,
    required this.totalSessions,
    required this.attendedSessions,
    required this.remainingSessions,
    this.nextSession,
    required this.showCoachFilter,
    this.isLoading = false,
    required this.weeklyProgress,
  });

  SessionsLoaded copyWith({
    List<CoachSummary>? coaches,
    List<BookingHistoryModel>? bookings,
    List<Session>? allSessions,
    List<Session>? upcomingSessions,
    List<Session>? historySessions,
    List<Session>? filteredSessions,
    DateTime? selectedDate,
    CoachSummary? selectedCoach,
    bool clearSelectedCoach = false,
    SessionTab? activeTab,
    int? totalSessions,
    int? attendedSessions,
    int? remainingSessions,
    Session? nextSession,
    bool clearNextSession = false,
    bool? showCoachFilter,
    bool? isLoading,
    WeeklyProgressSummary? weeklyProgress,
  }) {
    return SessionsLoaded(
      coaches: coaches ?? this.coaches,
      bookings: bookings ?? this.bookings,
      allSessions: allSessions ?? this.allSessions,
      upcomingSessions: upcomingSessions ?? this.upcomingSessions,
      historySessions: historySessions ?? this.historySessions,
      filteredSessions: filteredSessions ?? this.filteredSessions,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedCoach:
          clearSelectedCoach ? null : (selectedCoach ?? this.selectedCoach),
      activeTab: activeTab ?? this.activeTab,
      totalSessions: totalSessions ?? this.totalSessions,
      attendedSessions: attendedSessions ?? this.attendedSessions,
      remainingSessions: remainingSessions ?? this.remainingSessions,
      nextSession: clearNextSession ? null : (nextSession ?? this.nextSession),
      showCoachFilter: showCoachFilter ?? this.showCoachFilter,
      isLoading: isLoading ?? this.isLoading,
      weeklyProgress: weeklyProgress ?? this.weeklyProgress,
    );
  }

  @override
  List<Object?> get props => [
        coaches,
        bookings,
        allSessions,
        upcomingSessions,
        historySessions,
        filteredSessions,
        selectedDate,
        selectedCoach,
        activeTab,
        totalSessions,
        attendedSessions,
        remainingSessions,
        nextSession,
        showCoachFilter,
        isLoading,
        weeklyProgress,
      ];
}

class SessionsError extends SessionsState {
  final String message;

  const SessionsError(this.message);

  @override
  List<Object?> get props => [message];
}
