// models/mma_booking_model.dart
class MMABookingModel {
  final String? coachId;
  final String coachName;
  final String coachImage;
  final String? specialty;
  final String coachWhatsapp;
  final List<String> availableDays;
  final List<String> availableTimes;
  final List<int> sessionPackages;
  final double pricePerSession;

  MMABookingModel({
    this.coachId,
    required this.coachName,
    required this.coachImage,
    this.specialty,
    required this.coachWhatsapp,
    required this.availableDays,
    required this.availableTimes,
    required this.sessionPackages,
    required this.pricePerSession,
  });
}