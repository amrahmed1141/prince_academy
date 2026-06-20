import 'package:equatable/equatable.dart';
import 'package:prince_academy/features/booking/data/models/booking_model.dart';

abstract class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object?> get props => [];
}

class LoadBookingData extends BookingEvent {
  final String coachId;
  final String? coachName;
  final String? coachImage;

  const LoadBookingData({
    required this.coachId,
    this.coachName,
    this.coachImage,
  });

  @override
  List<Object?> get props => [coachId, coachName, coachImage];
}

class ToggleDay extends BookingEvent {
  final String day;

  const ToggleDay(this.day);

  @override
  List<Object?> get props => [day];
}

class SelectPaymentMethod extends BookingEvent {
  final PaymentMethod method;

  const SelectPaymentMethod(this.method);

  @override
  List<Object?> get props => [method];
}

class ClearMinSessionsWarning extends BookingEvent {
  const ClearMinSessionsWarning();
}

class SubmitBooking extends BookingEvent {
  const SubmitBooking();
}
