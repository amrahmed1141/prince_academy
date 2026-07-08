import 'package:equatable/equatable.dart';

abstract class BookingHistoryEvent extends Equatable {
  const BookingHistoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadBookingHistory extends BookingHistoryEvent {
  final bool forceRefresh;

  const LoadBookingHistory({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class FilterBookings extends BookingHistoryEvent {
  final String? status;

  const FilterBookings(this.status);

  @override
  List<Object?> get props => [status];
}
