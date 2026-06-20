import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/features/booking/data/repositories/booking_repository.dart';
import 'package:prince_academy/features/booking/presentation/bloc/booking_history_event.dart';
import 'package:prince_academy/features/booking/presentation/bloc/booking_history_state.dart';

class BookingHistoryBloc extends Bloc<BookingHistoryEvent, BookingHistoryState> {
  final BookingRepository _repository;

  BookingHistoryBloc(this._repository) : super(const BookingHistoryInitial()) {
    on<LoadBookingHistory>(_onLoadBookingHistory);
    on<FilterBookings>(_onFilterBookings);
  }

  Future<void> _onLoadBookingHistory(
    LoadBookingHistory event,
    Emitter<BookingHistoryState> emit,
  ) async {
    emit(const BookingHistoryLoading());
    try {
      final bookings = await _repository.getUserBookings();
      emit(BookingHistoryLoaded(allBookings: bookings));
    } catch (e) {
      emit(
        BookingHistoryError(
          e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  void _onFilterBookings(
    FilterBookings event,
    Emitter<BookingHistoryState> emit,
  ) {
    final current = state;
    if (current is! BookingHistoryLoaded) return;

    emit(
      BookingHistoryLoaded(
        allBookings: current.allBookings,
        activeFilter: event.status,
      ),
    );
  }
}
