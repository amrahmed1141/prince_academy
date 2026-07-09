import 'package:equatable/equatable.dart';

abstract class BookingDetailEvent extends Equatable {
  const BookingDetailEvent();

  @override
  List<Object?> get props => [];
}

class DeleteBooking extends BookingDetailEvent {
  final String bookingId;

  const DeleteBooking(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

class UpdateBookingDays extends BookingDetailEvent {
  final String bookingId;
  final List<String> days;

  const UpdateBookingDays({
    required this.bookingId,
    required this.days,
  });

  @override
  List<Object?> get props => [bookingId, days];
}

class RescheduleBooking extends BookingDetailEvent {
  final String bookingId;
  final DateTime startDate;

  const RescheduleBooking({
    required this.bookingId,
    required this.startDate,
  });

  @override
  List<Object?> get props => [bookingId, startDate];
}

class ResetBookingDetail extends BookingDetailEvent {
  const ResetBookingDetail();
}
