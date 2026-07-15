import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:prince_academy/features/booking/data/models/booking_model.dart';
import 'package:prince_academy/features/home/data/models/coach_session_model.dart';

abstract class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object?> get props => [];
}

/// Loads coach session and moves to step 1.
class LoadCoachBooking extends BookingEvent {
  final String coachId;
  final String? coachName;
  final String? coachImage;
  final String? specialty;
  final String? branchId;

  const LoadCoachBooking({
    required this.coachId,
    this.coachName,
    this.coachImage,
    this.specialty,
    this.branchId,
  });

  @override
  List<Object?> get props =>
      [coachId, coachName, coachImage, specialty, branchId];
}

class SelectCoach extends BookingEvent {
  final BookingCoach coach;

  const SelectCoach(this.coach);

  @override
  List<Object?> get props => [coach];
}

// ADDED: user selects training days per week (min 2)
class SelectDays extends BookingEvent {
  final List<String> days;

  const SelectDays(this.days);

  @override
  List<Object?> get props => [days];
}

class SelectStartDate extends BookingEvent {
  final DateTime date;

  const SelectStartDate(this.date);

  @override
  List<Object?> get props => [date];
}

class SelectPaymentMethod extends BookingEvent {
  final String method;

  const SelectPaymentMethod(this.method);

  @override
  List<Object?> get props => [method];
}

class CreateBooking extends BookingEvent {
  const CreateBooking();
}

class UploadScreenshot extends BookingEvent {
  final File file;

  const UploadScreenshot(this.file);

  @override
  List<Object?> get props => [file.path];
}

class ConfirmInstaPayPayment extends BookingEvent {
  const ConfirmInstaPayPayment();
}

// ADDED: fetch active/pending coach IDs for duplicate prevention
class LoadUserActiveBookings extends BookingEvent {
  const LoadUserActiveBookings();
}

// ADDED: RPC safety check before opening booking wizard
class CheckDuplicateBooking extends BookingEvent {
  final String coachId;
  final String? coachName;
  final String? coachImage;
  final String? specialty;
  final String? branchId;

  const CheckDuplicateBooking({
    required this.coachId,
    this.coachName,
    this.coachImage,
    this.specialty,
    this.branchId,
  });

  @override
  List<Object?> get props =>
      [coachId, coachName, coachImage, specialty, branchId];
}

/// Shared wizard data carried across step states.
class BookingWizardData extends Equatable {
  final BookingCoach coach;
  final CoachSessionModel session;
  final List<String> availableDays;
  final List<String> selectedDays;
  final String sessionTime;
  final double totalPrice;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<DateTime> sessionDates;
  final String? paymentMethod;
  final BookingModel? createdBooking;

  const BookingWizardData({
    required this.coach,
    required this.session,
    required this.availableDays,
    required this.selectedDays,
    required this.sessionTime,
    required this.totalPrice,
    this.startDate,
    this.endDate,
    this.sessionDates = const [],
    this.paymentMethod,
    this.createdBooking,
  });

  int get sessionCount => sessionDates.length;

  int get estimatedSessions =>
      selectedDays.isEmpty ? 0 : selectedDays.length * 4;

  BookingWizardData copyWith({
    BookingCoach? coach,
    CoachSessionModel? session,
    List<String>? availableDays,
    List<String>? selectedDays,
    String? sessionTime,
    double? totalPrice,
    DateTime? startDate,
    DateTime? endDate,
    List<DateTime>? sessionDates,
    String? paymentMethod,
    BookingModel? createdBooking,
  }) {
    return BookingWizardData(
      coach: coach ?? this.coach,
      session: session ?? this.session,
      availableDays: availableDays ?? this.availableDays,
      selectedDays: selectedDays ?? this.selectedDays,
      sessionTime: sessionTime ?? this.sessionTime,
      totalPrice: totalPrice ?? this.totalPrice,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      sessionDates: sessionDates ?? this.sessionDates,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdBooking: createdBooking ?? this.createdBooking,
    );
  }

  @override
  List<Object?> get props => [
        coach,
        session,
        availableDays,
        selectedDays,
        sessionTime,
        totalPrice,
        startDate,
        endDate,
        sessionDates,
        paymentMethod,
        createdBooking?.id,
      ];
}
