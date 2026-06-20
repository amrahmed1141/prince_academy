import 'package:equatable/equatable.dart';
import 'package:prince_academy/features/booking/data/models/booking_history_model.dart';

abstract class BookingHistoryState extends Equatable {
  const BookingHistoryState();

  @override
  List<Object?> get props => [];
}

class BookingHistoryInitial extends BookingHistoryState {
  const BookingHistoryInitial();
}

class BookingHistoryLoading extends BookingHistoryState {
  const BookingHistoryLoading();
}

class BookingHistoryLoaded extends BookingHistoryState {
  final List<BookingHistoryModel> allBookings;
  final String? activeFilter;

  const BookingHistoryLoaded({
    required this.allBookings,
    this.activeFilter,
  });

  List<BookingHistoryModel> get bookings {
    if (activeFilter == null) return allBookings;
    return allBookings
        .where((booking) => booking.effectiveDisplayStatus == activeFilter)
        .toList();
  }

  int countForFilter(String? filter) {
    if (filter == null) return allBookings.length;
    return allBookings
        .where((booking) => booking.effectiveDisplayStatus == filter)
        .length;
  }

  @override
  List<Object?> get props => [allBookings, activeFilter];
}

class BookingHistoryError extends BookingHistoryState {
  final String message;

  const BookingHistoryError(this.message);

  @override
  List<Object?> get props => [message];
}
