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

  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _onLoadHomeData(
    LoadHomeData event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final results = await Future.wait([
        sessionsRepository.getSessions(),
        bookingRepository.getUserBookings(),
        branchRepository.getAllBranches(),
      ]);

      _allSessions = results[0] as List<Session>;
      final bookings = results[1] as List<BookingHistoryModel>;
      final branches = results[2] as List<Branch>;

      final lastBooking = _latestBooking(bookings);
      final branch = branches.isNotEmpty ? branches.first : null;
      final selectedDate = state.selectedDate;
      final filtered = _filterByDate(_allSessions, selectedDate);

      emit(
        state.copyWith(
          isLoading: false,
          allSessions: _allSessions,
          sessionsForSelectedDate: filtered,
          upcomingSession: _resolveUpcomingSession(
            selectedDateSessions: filtered,
            allSessions: _allSessions,
          ),
          bookings: bookings,
          lastBooking: lastBooking,
          branch: branch,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
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
    return sessions
        .where((s) => isSameDay(s.sessionDate, date))
        .toList()
      ..sort((a, b) => a.selectedTime.compareTo(b.selectedTime));
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
