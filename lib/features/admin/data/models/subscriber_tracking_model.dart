import 'package:equatable/equatable.dart';

class SubscriberTrackingModel extends Equatable {
  final String userId;
  final String fullName;
  final String? phone;
  final int bookingCount;
  final int activeCount;
  final int expiredCount;
  final DateTime? latestBookingDate;
  final List<String> coachNames;

  const SubscriberTrackingModel({
    required this.userId,
    required this.fullName,
    this.phone,
    required this.bookingCount,
    required this.activeCount,
    required this.expiredCount,
    this.latestBookingDate,
    this.coachNames = const [],
  });

  String get initials {
    final parts = fullName
        .trim()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase())
        .take(2)
        .join();
    return parts.isEmpty ? '?' : parts;
  }

  @override
  List<Object?> get props => [
        userId,
        fullName,
        phone,
        bookingCount,
        activeCount,
        expiredCount,
        latestBookingDate,
        coachNames,
      ];
}
