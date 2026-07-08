import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/features/booking/data/repositories/booking_repository.dart';
import 'package:prince_academy/features/booking/presentation/bloc/booking_detail_event.dart';
import 'package:prince_academy/features/booking/presentation/bloc/booking_detail_state.dart';

class BookingDetailBloc
    extends Bloc<BookingDetailEvent, BookingDetailState> {
  final BookingRepository _repository;

  BookingDetailBloc(this._repository)
      : super(const BookingDetailInitial()) {
    on<DeleteBooking>(_onDeleteBooking);
    on<UpdateBookingDays>(_onUpdateBookingDays);
    on<RescheduleBooking>(_onRescheduleBooking);
  }

  Future<void> _onDeleteBooking(
    DeleteBooking event,
    Emitter<BookingDetailState> emit,
  ) async {
    emit(const BookingDetailLoading());
    try {
      await _repository.cancelBooking(event.bookingId);
      emit(const BookingDetailSuccess('Booking cancelled successfully'));
    } catch (e) {
      emit(BookingDetailError(
        e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onUpdateBookingDays(
    UpdateBookingDays event,
    Emitter<BookingDetailState> emit,
  ) async {
    emit(const BookingDetailLoading());
    try {
      await _repository.updateBookingDays(
        bookingId: event.bookingId,
        days: event.days,
      );
      emit(const BookingDetailSuccess('Booking updated successfully'));
    } catch (e) {
      emit(BookingDetailError(
        e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onRescheduleBooking(
    RescheduleBooking event,
    Emitter<BookingDetailState> emit,
  ) async {
    emit(const BookingDetailLoading());
    try {
      await _repository.rescheduleBooking(
        bookingId: event.bookingId,
        startDate: event.startDate,
      );
      emit(const BookingDetailSuccess('Booking rescheduled successfully'));
    } catch (e) {
      emit(BookingDetailError(
        e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }
}
