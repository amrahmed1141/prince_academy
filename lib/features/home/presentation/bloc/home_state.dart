import 'package:equatable/equatable.dart';
import 'package:prince_academy/features/admin/data/models/branch_model.dart';
import 'package:prince_academy/features/booking/data/models/booking_history_model.dart';
import 'package:prince_academy/features/sessions/data/models/session_model.dart';

class HomeState extends Equatable {
  final bool isLoading;
  final bool isRefreshing;
  final bool hasLoaded;
  final DateTime selectedDate;
  final List<Session> allSessions;
  final List<Session> sessionsForSelectedDate;
  final Session? upcomingSession;
  final List<BookingHistoryModel> bookings;
  final BookingHistoryModel? lastBooking;
  final Branch? branch;
  final String? error;

  const HomeState({
    this.isLoading = false,
    this.isRefreshing = false,
    this.hasLoaded = false,
    required this.selectedDate,
    this.allSessions = const [],
    this.sessionsForSelectedDate = const [],
    this.upcomingSession,
    this.bookings = const [],
    this.lastBooking,
    this.branch,
    this.error,
  });

  factory HomeState.initial() {
    final now = DateTime.now();
    return HomeState(
      isLoading: true,
      isRefreshing: false,
      hasLoaded: false,
      selectedDate: DateTime(now.year, now.month, now.day),
    );
  }

  bool get hasSessionsForSelectedDate => sessionsForSelectedDate.isNotEmpty;

  HomeState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    bool? hasLoaded,
    DateTime? selectedDate,
    List<Session>? allSessions,
    List<Session>? sessionsForSelectedDate,
    Session? upcomingSession,
    bool clearUpcomingSession = false,
    List<BookingHistoryModel>? bookings,
    BookingHistoryModel? lastBooking,
    bool clearLastBooking = false,
    Branch? branch,
    bool clearBranch = false,
    String? error,
    bool clearError = false,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      selectedDate: selectedDate ?? this.selectedDate,
      allSessions: allSessions ?? this.allSessions,
      sessionsForSelectedDate:
          sessionsForSelectedDate ?? this.sessionsForSelectedDate,
      upcomingSession:
          clearUpcomingSession ? null : (upcomingSession ?? this.upcomingSession),
      bookings: bookings ?? this.bookings,
      lastBooking:
          clearLastBooking ? null : (lastBooking ?? this.lastBooking),
      branch: clearBranch ? null : (branch ?? this.branch),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isRefreshing,
        hasLoaded,
        selectedDate,
        allSessions,
        sessionsForSelectedDate,
        upcomingSession,
        bookings,
        lastBooking,
        branch,
        error,
      ];
}
