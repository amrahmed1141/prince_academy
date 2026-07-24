import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/features/booking/data/models/booking_history_model.dart';
import 'package:prince_academy/features/sessions/data/models/coach_summary_model.dart';
import 'package:prince_academy/features/sessions/data/models/session_model.dart';
import 'package:prince_academy/features/sessions/data/repositories/sessions_repository.dart';
import 'package:prince_academy/features/sessions/domain/weekly_progress_calculator.dart';
import 'package:prince_academy/features/sessions/presentation/bloc/sessions_event.dart';
import 'package:prince_academy/features/sessions/presentation/bloc/sessions_state.dart';

class SessionsBloc extends Bloc<SessionsEvent, SessionsState> {
  final SessionsRepository repository;
  List<CoachSummary> _allCoaches = [];
  List<Session> _allSessions = [];
  List<BookingHistoryModel> _allBookings = [];
  StreamSubscription<SessionsSnapshot>? _subscription;

  SessionsBloc({required this.repository}) : super(SessionsInitial()) {
    on<SessionsStarted>(_onSessionsStarted);
    on<RefreshSessions>(_onRefreshSessions);
    on<SessionsDataUpdated>(_onSessionsDataUpdated);
    on<SessionsDataFailed>(_onSessionsDataFailed);
    on<SelectCoach>(_onSelectCoach);
    on<SwitchTab>(_onSwitchTab);
    on<SelectDate>(_onSelectDate);
    on<SearchSessions>(_onSearchSessions);
  }

  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime startOfWeek(DateTime date) {
    final d = dateOnly(date);
    return d.subtract(Duration(days: d.weekday - DateTime.monday));
  }

  static List<Session> filterSessionsByDate(
    List<Session> sessions,
    DateTime date,
  ) {
    return sessions.where((s) => isSameDay(s.sessionDate, date)).toList()
      ..sort((a, b) => a.selectedTime.compareTo(b.selectedTime));
  }

  Future<void> _onSessionsStarted(
    SessionsStarted event,
    Emitter<SessionsState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = repository.sessionsStream.listen(
      (snapshot) => add(SessionsDataUpdated(snapshot)),
      onError: (Object error) {
        add(SessionsDataFailed(error.toString()));
      },
    );

    final cached = repository.cachedSnapshot;
    if (cached != null) {
      _applySnapshot(cached, emit);
      unawaited(
        repository.refreshSessions(force: true).catchError((_) => cached),
      );
    } else {
      emit(SessionsLoading());
      try {
        await repository.refreshSessions(force: true);
      } catch (e) {
        emit(SessionsError('Failed to load sessions: $e'));
      }
    }
  }

  Future<void> _onRefreshSessions(
    RefreshSessions event,
    Emitter<SessionsState> emit,
  ) async {
    final currentState = state;
    if (currentState is SessionsLoaded) {
      emit(currentState.copyWith(isLoading: true));
    } else if (currentState is SessionsInitial) {
      emit(SessionsLoading());
    }

    try {
      if (event.force) {
        repository.invalidateCache();
      }
      await repository.refreshSessions(force: true);
    } catch (e) {
      if (currentState is SessionsLoaded) {
        emit(currentState.copyWith(isLoading: false));
      } else {
        emit(SessionsError('Failed to load sessions: $e'));
      }
    }
  }

  void _onSessionsDataUpdated(
    SessionsDataUpdated event,
    Emitter<SessionsState> emit,
  ) {
    _applySnapshot(event.snapshot, emit, isLoading: false);
  }

  void _onSessionsDataFailed(
    SessionsDataFailed event,
    Emitter<SessionsState> emit,
  ) {
    if (state is SessionsLoaded) return;
    emit(SessionsError(event.message.replaceFirst('Exception: ', '')));
  }

  void _applySnapshot(
    SessionsSnapshot snapshot,
    Emitter<SessionsState> emit, {
    bool isLoading = false,
  }) {
    _allCoaches = snapshot.coaches;
    _allSessions = snapshot.sessions;
    _allBookings = snapshot.bookings;

    final currentState = state;
    final selectedCoach =
        currentState is SessionsLoaded ? currentState.selectedCoach : null;
    final activeTab = currentState is SessionsLoaded
        ? currentState.activeTab
        : SessionTab.upcoming;
    final selectedDate = currentState is SessionsLoaded
        ? currentState.selectedDate
        : dateOnly(DateTime.now());
    final searchQuery =
        currentState is SessionsLoaded ? currentState.searchQuery : '';

    final coachId = selectedCoach?.coachId;
    final sessions = coachId == null
        ? _allSessions
        : _allSessions.where((s) => s.coachId == coachId).toList();
    final bookings = _filterBookings(
      coachId: coachId,
      searchQuery: searchQuery,
    );

    emit(
      _buildLoadedState(
        coaches: _allCoaches,
        bookings: bookings,
        sessions: sessions,
        selectedCoach: selectedCoach,
        activeTab: activeTab,
        showFilter: _allCoaches.length > 1,
        selectedDate: selectedDate,
        isLoading: isLoading,
        searchQuery: searchQuery,
      ),
    );
  }

  void _onSelectCoach(
    SelectCoach event,
    Emitter<SessionsState> emit,
  ) {
    final currentState = state;
    if (currentState is! SessionsLoaded) return;

    final sessions = event.coachId == null
        ? _allSessions
        : _allSessions.where((s) => s.coachId == event.coachId).toList();

    final bookings = _filterBookings(
      coachId: event.coachId,
      searchQuery: currentState.searchQuery,
    );

    CoachSummary? selectedCoach;
    if (event.coachId != null) {
      for (final coach in _allCoaches) {
        if (coach.coachId == event.coachId) {
          selectedCoach = coach;
          break;
        }
      }
    }

    emit(
      _buildLoadedState(
        coaches: _allCoaches,
        bookings: bookings,
        sessions: sessions,
        selectedCoach: selectedCoach,
        activeTab: currentState.activeTab,
        showFilter: currentState.showCoachFilter,
        selectedDate: currentState.selectedDate,
        isLoading: currentState.isLoading,
        searchQuery: currentState.searchQuery,
      ),
    );
  }

  void _onSearchSessions(
    SearchSessions event,
    Emitter<SessionsState> emit,
  ) {
    final currentState = state;
    if (currentState is! SessionsLoaded) return;

    final query = event.query.trim().toLowerCase();
    final coachId = currentState.selectedCoach?.coachId;
    final sessions = coachId == null
        ? _allSessions
        : _allSessions.where((s) => s.coachId == coachId).toList();
    final bookings = _filterBookings(coachId: coachId, searchQuery: query);

    emit(
      _buildLoadedState(
        coaches: _allCoaches,
        bookings: bookings,
        sessions: sessions,
        selectedCoach: currentState.selectedCoach,
        activeTab: currentState.activeTab,
        showFilter: currentState.showCoachFilter,
        selectedDate: currentState.selectedDate,
        isLoading: currentState.isLoading,
        searchQuery: query,
      ),
    );
  }

  List<BookingHistoryModel> _filterBookings({
    required String? coachId,
    required String searchQuery,
  }) {
    var bookings = coachId == null
        ? List<BookingHistoryModel>.from(_allBookings)
        : _allBookings.where((b) => b.coachId == coachId).toList();

    if (searchQuery.isEmpty) return bookings;

    return bookings.where((booking) {
      return booking.coachName.toLowerCase().contains(searchQuery) ||
          (booking.coachSpecialty?.toLowerCase().contains(searchQuery) ??
              false) ||
          (booking.branchName?.toLowerCase().contains(searchQuery) ?? false) ||
          booking.effectiveDisplayStatus.toLowerCase().contains(searchQuery) ||
          (booking.selectedTime?.toLowerCase().contains(searchQuery) ?? false);
    }).toList();
  }

  void _onSelectDate(
    SelectDate event,
    Emitter<SessionsState> emit,
  ) {
    final currentState = state;
    if (currentState is! SessionsLoaded) return;

    final selectedDate = dateOnly(event.date);
    emit(
      currentState.copyWith(
        selectedDate: selectedDate,
        filteredSessions: filterSessionsByDate(_allSessions, selectedDate),
      ),
    );
  }

  void _onSwitchTab(
    SwitchTab event,
    Emitter<SessionsState> emit,
  ) {
    final currentState = state;
    if (currentState is! SessionsLoaded) return;

    emit(currentState.copyWith(activeTab: event.tab));
  }

  SessionsLoaded _buildLoadedState({
    required List<CoachSummary> coaches,
    required List<BookingHistoryModel> bookings,
    required List<Session> sessions,
    required CoachSummary? selectedCoach,
    required SessionTab activeTab,
    required bool showFilter,
    required DateTime selectedDate,
    bool isLoading = false,
    String searchQuery = '',
  }) {
    final upcoming = sessions.where((s) => s.isUpcoming || s.isToday).toList()
      ..sort((a, b) => a.sessionDate.compareTo(b.sessionDate));

    final history = sessions.where((s) => s.isCompleted || s.isMissed).toList()
      ..sort((a, b) => b.sessionDate.compareTo(a.sessionDate));

    final total = selectedCoach == null
        ? coaches.fold(0, (sum, c) => sum + c.totalSessions)
        : selectedCoach.totalSessions;

    final attended = selectedCoach == null
        ? coaches.fold(0, (sum, c) => sum + c.attendedSessions)
        : selectedCoach.attendedSessions;

    final remaining = selectedCoach == null
        ? coaches.fold(0, (sum, c) => sum + c.remainingSessions)
        : selectedCoach.remainingSessions;

    final nextSession = upcoming.isNotEmpty ? upcoming.first : null;

    final normalizedDate = dateOnly(selectedDate);
    final filtered = filterSessionsByDate(sessions, normalizedDate);

    final weeklyProgress = WeeklyProgressCalculator.calculate(
      bookings: _allBookings,
      sessions: _allSessions,
    );

    return SessionsLoaded(
      coaches: coaches,
      bookings: bookings,
      allSessions: sessions,
      upcomingSessions: upcoming,
      historySessions: history,
      filteredSessions: filtered,
      selectedDate: normalizedDate,
      selectedCoach: selectedCoach,
      activeTab: activeTab,
      totalSessions: total,
      attendedSessions: attended,
      remainingSessions: remaining,
      nextSession: nextSession,
      showCoachFilter: showFilter,
      isLoading: isLoading,
      weeklyProgress: weeklyProgress,
      searchQuery: searchQuery,
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
