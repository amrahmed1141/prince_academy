import 'package:equatable/equatable.dart';
import 'package:prince_academy/features/booking/data/models/booking_model.dart';
import 'package:prince_academy/features/booking/presentation/bloc/booking_event.dart';

abstract class BookingState extends Equatable {
  const BookingState({this.bookedCoachIds = const []});

  final List<String> bookedCoachIds;

  @override
  List<Object?> get props => [bookedCoachIds];
}

class BookingInitial extends BookingState {
  const BookingInitial({super.bookedCoachIds});
}

class BookingLoading extends BookingState {
  const BookingLoading({super.bookedCoachIds});
}

// ADDED: duplicate booking safety check in progress
class BookingCheckLoading extends BookingState {
  const BookingCheckLoading({super.bookedCoachIds});
}

// ADDED: result of duplicate booking check (booking page safety net)
class BookingCheckResult extends BookingState {
  final bool isDuplicate;
  final String? existingBookingId;
  final String? existingCoachName;

  const BookingCheckResult({
    required this.isDuplicate,
    this.existingBookingId,
    this.existingCoachName,
    super.bookedCoachIds,
  });

  @override
  List<Object?> get props => [
        ...super.props,
        isDuplicate,
        existingBookingId,
        existingCoachName,
      ];
}

class BookingStep1CoachSelected extends BookingState {
  final BookingWizardData data;

  const BookingStep1CoachSelected(this.data, {super.bookedCoachIds});

  @override
  List<Object?> get props => [...super.props, data];
}

// ADDED: Step 2 — user picks training days per week (min 2)
class BookingStep2DaysSelected extends BookingState {
  final BookingWizardData data;
  final List<String> availableDays;
  final List<String> selectedDays;
  final int estimatedSessions;

  const BookingStep2DaysSelected({
    required this.data,
    required this.availableDays,
    required this.selectedDays,
    required this.estimatedSessions,
    super.bookedCoachIds,
  });

  bool get isValid => selectedDays.length >= 2;

  @override
  List<Object?> get props => [
        ...super.props,
        data,
        availableDays,
        selectedDays,
        estimatedSessions,
      ];
}

class BookingStep3DateSelected extends BookingState {
  final BookingWizardData data;
  final DateTime startDate;
  final DateTime endDate;
  final List<DateTime> sessionDates;
  final int sessionCount;

  const BookingStep3DateSelected({
    required this.data,
    required this.startDate,
    required this.endDate,
    required this.sessionDates,
    required this.sessionCount,
    super.bookedCoachIds,
  });

  @override
  List<Object?> get props => [
        ...super.props,
        data,
        startDate,
        endDate,
        sessionDates,
        sessionCount,
      ];
}

class BookingStep4PaymentSelected extends BookingState {
  final BookingWizardData data;
  final DateTime startDate;
  final DateTime endDate;
  final List<DateTime> sessionDates;
  final int sessionCount;
  final String paymentMethod;

  const BookingStep4PaymentSelected({
    required this.data,
    required this.startDate,
    required this.endDate,
    required this.sessionDates,
    required this.sessionCount,
    required this.paymentMethod,
    super.bookedCoachIds,
  });

  @override
  List<Object?> get props => [
        ...super.props,
        data,
        startDate,
        endDate,
        sessionDates,
        sessionCount,
        paymentMethod,
      ];
}

class BookingCreating extends BookingState {
  final BookingWizardData data;

  const BookingCreating(this.data, {super.bookedCoachIds});

  @override
  List<Object?> get props => [...super.props, data];
}

class BookingCreated extends BookingState {
  final BookingModel booking;
  final String message;
  final BookingWizardData data;

  const BookingCreated({
    required this.booking,
    required this.message,
    required this.data,
    super.bookedCoachIds,
  });

  @override
  List<Object?> get props => [...super.props, booking, message, data];
}

class BookingError extends BookingState {
  final String message;

  const BookingError(this.message, {super.bookedCoachIds});

  @override
  List<Object?> get props => [...super.props, message];
}
