import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/features/admin/data/models/branch_model.dart';
import 'package:prince_academy/features/admin/data/repositories/branch_repository.dart';
import 'package:prince_academy/features/booking/data/models/booking_history_model.dart';
import 'package:prince_academy/features/booking/data/repositories/booking_repository.dart';
import 'package:prince_academy/features/home/presentation/bloc/home_event.dart';
import 'package:prince_academy/features/home/presentation/bloc/home_state.dart';
import 'package:prince_academy/features/sessions/data/models/session_model.dart';
import 'package:prince_academy/features/sessions/data/repositories/sessions_repository.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final SessionsRepository sessionsRepository;
  final BookingRepository bookingRepository;
  final BranchRepository branchRepository;

  List<Session> _allSessions = [];

  HomeBloc({
    required this.sessionsRepository,
    required this.bookingRepository,
    required this.branchRepository,
  }) : super(HomeState.initial()) {
    on<LoadHomeData>(_onLoadHomeData);
    on<SelectDate>(_onSelectDate);
  }

  static DateTime dateOnly(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    final al = a.toLocal();
    final bl = b.toLocal();
    return al.year == bl.year && al.month == bl.month && al.day == bl.day;
  }

  static DateTime today() => dateOnly(DateTime.now());

  Future<void> _onLoadHomeData(
    LoadHomeData event,
    Emitter<HomeState> emit,
  ) async {
    final current = state;
    final firstLoad = !current.hasLoaded;
    // Default to today on first open; keep the user's pick on later refreshes.
    final selectedDate = firstLoad ? today() : dateOnly(current.selectedDate);

    if (firstLoad) {
      final cachedSnapshot = sessionsRepository.cachedSnapshot;
      final cachedBookings = bookingRepository.cachedBookings;
      final cachedBranches = branchRepository.cachedBranches;
      if (cachedSnapshot != null ||
          cachedBookings != null ||
          cachedBranches != null) {
        final cachedSessions = cachedSnapshot?.sessions ?? const <Session>[];
        _allSessions = cachedSessions;
        final filtered = _filterByDate(cachedSessions, selectedDate);
        final bookings = cachedBookings ?? const <BookingHistoryModel>[];
        final branch =
            (cachedBranches != null && cachedBranches.isNotEmpty)
                ? cachedBranches.first
                : null;

        emit(
          current.copyWith(
            isLoading: false,
            isRefreshing: true,
            hasLoaded: true,
            clearError: true,
            selectedDate: selectedDate,
            allSessions: cachedSessions,
            sessionsForSelectedDate: filtered,
            upcomingSession: _resolveUpcomingSession(
              selectedDateSessions: filtered,
              allSessions: cachedSessions,
            ),
            bookings: bookings,
            lastBooking: _latestBooking(bookings),
            branch: branch,
          ),
        );
      } else {
        emit(current.copyWith(
          isLoading: true,
          isRefreshing: false,
          clearError: true,
          selectedDate: selectedDate,
        ));
      }
    } else {
      emit(current.copyWith(isRefreshing: true, clearError: true));
    }

    try {
      // Always refresh after any cached paint so UI stays fresh (SWR).
      final results = await Future.wait([
        sessionsRepository.getSessions(force: true),
        bookingRepository.getUserBookings(force: true),
        branchRepository.getAllBranches(force: true),
      ]);

      _allSessions = results[0] as List<Session>;
      final bookings = results[1] as List<BookingHistoryModel>;
      final branches = results[2] as List<Branch>;

      final lastBooking = _latestBooking(bookings);
      final branch = branches.isNotEmpty ? branches.first : null;
      final activeDate = dateOnly(state.selectedDate);
      final filtered = _filterByDate(_allSessions, activeDate);

      final next = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        hasLoaded: true,
        clearError: true,
        selectedDate: activeDate,
        allSessions: _allSessions,
        sessionsForSelectedDate: filtered,
        upcomingSession: _resolveUpcomingSession(
          selectedDateSessions: filtered,
          allSessions: _allSessions,
        ),
        bookings: bookings,
        lastBooking: lastBooking,
        branch: branch,
      );

      // Skip full rebuild when payload is unchanged; only clear refresh flags.
      if (state.hasLoaded && _sameHomePayload(state, next)) {
        if (state.isRefreshing || state.isLoading || state.error != null) {
          emit(state.copyWith(
            isRefreshing: false,
            isLoading: false,
            clearError: true,
          ));
        }
        return;
      }

      emit(next);
    } catch (e) {
      if (state.hasLoaded) {
        emit(
          state.copyWith(
            isLoading: false,
            isRefreshing: false,
            error: e.toString().replaceFirst('Exception: ', ''),
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          isLoading: false,
          isRefreshing: false,
          error: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  bool _sameHomePayload(HomeState a, HomeState b) {
    if (a.bookings.length != b.bookings.length) return false;
    if (a.allSessions.length != b.allSessions.length) return false;
    if (a.branch?.id != b.branch?.id) return false;
    if (a.lastBooking?.bookingId != b.lastBooking?.bookingId) return false;
    if (a.upcomingSession?.bookingId != b.upcomingSession?.bookingId ||
        a.upcomingSession?.sessionDate != b.upcomingSession?.sessionDate ||
        a.upcomingSession?.selectedTime != b.upcomingSession?.selectedTime) {
      return false;
    }
    for (var i = 0; i < a.bookings.length; i++) {
      if (a.bookings[i].bookingId != b.bookings[i].bookingId ||
          a.bookings[i].displayStatus != b.bookings[i].displayStatus) {
        return false;
      }
    }
    for (var i = 0; i < a.allSessions.length; i++) {
      final left = a.allSessions[i];
      final right = b.allSessions[i];
      if (left.bookingId != right.bookingId ||
          left.sessionDate != right.sessionDate ||
          left.sessionStatus != right.sessionStatus ||
          left.attendanceStatus != right.attendanceStatus) {
        return false;
      }
    }
    return true;
  }

  void _onSelectDate(SelectDate event, Emitter<HomeState> emit) {
    final selectedDate = dateOnly(event.date);
    final filtered = _filterByDate(_allSessions, selectedDate);

    emit(
      state.copyWith(
        selectedDate: selectedDate,
        sessionsForSelectedDate: filtered,
        upcomingSession: _resolveUpcomingSession(
          selectedDateSessions: filtered,
          allSessions: _allSessions,
        ),
      ),
    );
  }

  List<Session> _filterByDate(List<Session> sessions, DateTime date) {
    final target = dateOnly(date);
    final isToday = isSameDay(target, today());

    return sessions.where((s) {
      if (isSameDay(s.sessionDate, target)) return true;
      // Match Sessions-page "today" logic when calendar is on today.
      if (isToday && s.isToday) return true;
      return false;
    }).toList()
      ..sort((a, b) {
        final dateCompare =
            dateOnly(a.sessionDate).compareTo(dateOnly(b.sessionDate));
        if (dateCompare != 0) return dateCompare;
        return a.selectedTime.compareTo(b.selectedTime);
      });
  }

  Session? _firstUpcoming(List<Session> sessions) {
    final upcoming = sessions
        .where((s) => s.isUpcoming || s.isToday)
        .toList()
      ..sort((a, b) => a.selectedTime.compareTo(b.selectedTime));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  Session? _resolveUpcomingSession({
    required List<Session> selectedDateSessions,
    required List<Session> allSessions,
  }) {
    final selectedDateUpcoming = _firstUpcoming(selectedDateSessions);
    if (selectedDateUpcoming != null) {
      return selectedDateUpcoming;
    }

    final globalUpcoming = allSessions
        .where((s) => s.isUpcoming || s.isToday)
        .toList()
      ..sort((a, b) {
        final dateCompare = a.sessionDate.compareTo(b.sessionDate);
        if (dateCompare != 0) {
          return dateCompare;
        }
        return a.selectedTime.compareTo(b.selectedTime);
      });
    return globalUpcoming.isEmpty ? null : globalUpcoming.first;
  }

  BookingHistoryModel? _latestBooking(List<BookingHistoryModel> bookings) {
    if (bookings.isEmpty) return null;
    final sorted = List<BookingHistoryModel>.from(bookings)
      ..sort((a, b) {
        final aDate = a.createdAt ?? a.subscriptionStart ?? DateTime(1970);
        final bDate = b.createdAt ?? b.subscriptionStart ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });
    return sorted.first;
  }
}
