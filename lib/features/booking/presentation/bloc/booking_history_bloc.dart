import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/features/booking/data/models/booking_history_model.dart';
import 'package:prince_academy/features/booking/data/repositories/booking_repository.dart';
import 'package:prince_academy/features/booking/presentation/bloc/booking_history_event.dart';
import 'package:prince_academy/features/booking/presentation/bloc/booking_history_state.dart';

class BookingHistoryBloc extends Bloc<BookingHistoryEvent, BookingHistoryState> {
  final BookingRepository _repository;
  StreamSubscription<List<BookingHistoryModel>>? _bookingsSubscription;

  BookingHistoryBloc(this._repository) : super(const BookingHistoryInitial()) {
    on<LoadBookingHistory>(_onLoadBookingHistory);
    on<FilterBookings>(_onFilterBookings);
    on<_BookingHistoryRealtimeUpdated>(_onRealtimeUpdated);
  }

  Future<void> _onLoadBookingHistory(
    LoadBookingHistory event,
    Emitter<BookingHistoryState> emit,
  ) async {
    _ensureRealtimeSubscription();

    final current = state;
    final isFirstLoad = current is! BookingHistoryLoaded;
    if (isFirstLoad) {
      final cached = _repository.cachedBookings;
      if (cached != null) {
        emit(BookingHistoryLoaded(allBookings: cached, isRefreshing: true));
      } else {
        emit(const BookingHistoryLoading());
      }
    } else {
      emit(current.copyWith(isRefreshing: true));
    }

    try {
      final activeFilter = current is BookingHistoryLoaded ? current.activeFilter : null;
      final bookings = await _repository.getUserBookings(force: event.forceRefresh);
      emit(
        BookingHistoryLoaded(
          allBookings: bookings,
          activeFilter: activeFilter,
          isRefreshing: false,
        ),
      );
    } catch (e) {
      if (current is BookingHistoryLoaded) {
        emit(current.copyWith(isRefreshing: false));
      } else {
        emit(
          BookingHistoryError(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        );
      }
    }
  }

  void _onFilterBookings(
    FilterBookings event,
    Emitter<BookingHistoryState> emit,
  ) {
    final current = state;
    if (current is! BookingHistoryLoaded) return;

    emit(
      current.copyWith(
        activeFilter: event.status,
      ),
    );
  }

  void _onRealtimeUpdated(
    _BookingHistoryRealtimeUpdated event,
    Emitter<BookingHistoryState> emit,
  ) {
    final current = state;
    if (current is! BookingHistoryLoaded) {
      emit(BookingHistoryLoaded(allBookings: event.bookings));
      return;
    }
    emit(current.copyWith(allBookings: event.bookings, isRefreshing: false));
  }

  void _ensureRealtimeSubscription() {
    _bookingsSubscription ??= _repository.bookingsStream.listen(
      (bookings) => add(_BookingHistoryRealtimeUpdated(bookings)),
    );
  }

  @override
  Future<void> close() async {
    await _bookingsSubscription?.cancel();
    return super.close();
  }
}

class _BookingHistoryRealtimeUpdated extends BookingHistoryEvent {
  final List<BookingHistoryModel> bookings;

  const _BookingHistoryRealtimeUpdated(this.bookings);

  @override
  List<Object?> get props => [bookings];
}
