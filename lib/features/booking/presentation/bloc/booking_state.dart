import 'package:equatable/equatable.dart';
import 'package:prince_academy/features/booking/data/models/booking_model.dart';
import 'package:prince_academy/features/home/data/models/coach_session_model.dart';

abstract class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => [];
}

class BookingInitial extends BookingState {
  const BookingInitial();
}

class BookingLoading extends BookingState {
  const BookingLoading();
}

class BookingLoaded extends BookingState {
  final CoachSessionModel session;
  final String coachName;
  final String coachImage;
  final List<String> selectedDays;
  final String? selectedTime;
  final PaymentMethod? paymentMethod;
  final double totalPrice;
  final bool isLocked;
  final bool showMinSessionsWarning;

  const BookingLoaded({
    required this.session,
    required this.coachName,
    required this.coachImage,
    this.selectedDays = const [],
    this.selectedTime,
    this.paymentMethod,
    this.totalPrice = 0,
    this.isLocked = false,
    this.showMinSessionsWarning = false,
  });

  int get sessionsPerWeek => session.sessionsPerWeek;

  String get fixedTime =>
      session.timeSlots.isNotEmpty ? session.timeSlots.first : 'Time not set';

  bool get canContinue {
    if (selectedDays.isEmpty || paymentMethod == null) {
      return false;
    }
    if (sessionsPerWeek == 1) {
      return selectedDays.length == 1;
    }
    return selectedDays.length >= 2;
  }

  BookingLoaded copyWith({
    CoachSessionModel? session,
    String? coachName,
    String? coachImage,
    List<String>? selectedDays,
    String? selectedTime,
    PaymentMethod? paymentMethod,
    double? totalPrice,
    bool? isLocked,
    bool? showMinSessionsWarning,
  }) {
    return BookingLoaded(
      session: session ?? this.session,
      coachName: coachName ?? this.coachName,
      coachImage: coachImage ?? this.coachImage,
      selectedDays: selectedDays ?? this.selectedDays,
      selectedTime: selectedTime ?? this.selectedTime,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      totalPrice: totalPrice ?? this.totalPrice,
      isLocked: isLocked ?? this.isLocked,
      showMinSessionsWarning:
          showMinSessionsWarning ?? this.showMinSessionsWarning,
    );
  }

  @override
  List<Object?> get props => [
        session,
        coachName,
        coachImage,
        selectedDays,
        selectedTime,
        paymentMethod,
        totalPrice,
        isLocked,
        showMinSessionsWarning,
      ];
}

class BookingSubmitting extends BookingState {
  final BookingLoaded data;

  const BookingSubmitting(this.data);

  @override
  List<Object?> get props => [data];
}

class BookingSubmitFailed extends BookingState {
  final BookingLoaded data;
  final String message;

  const BookingSubmitFailed(this.data, this.message);

  @override
  List<Object?> get props => [data, message];
}

class BookingSuccess extends BookingState {
  final BookingModel booking;
  final String? qrCode;

  const BookingSuccess(this.booking, {this.qrCode});

  @override
  List<Object?> get props => [booking, qrCode];
}

class BookingError extends BookingState {
  final String message;

  const BookingError(this.message);

  @override
  List<Object?> get props => [message];
}
