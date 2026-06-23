import 'package:prince_academy/features/admin/data/models/coach_tracking_overview_model.dart';
import 'package:prince_academy/features/admin/data/models/subscriber_tracking_model.dart';
import 'package:prince_academy/features/booking/data/models/booking_history_model.dart';

class TrackingDataMapper {
  static List<CoachTrackingOverview> buildCoachOverview(
    List<BookingHistoryModel> bookings,
  ) {
    final grouped = <String, List<BookingHistoryModel>>{};
    for (final booking in bookings) {
      if (booking.coachId.isEmpty) continue;
      grouped.putIfAbsent(booking.coachId, () => []).add(booking);
    }

    return grouped.entries.map((entry) {
      final rows = entry.value;
      final first = rows.first;
      final uniqueUsers = rows.map((row) => row.userId).toSet();

      return CoachTrackingOverview(
        coachId: entry.key,
        coachName: first.coachName,
        coachPhoto: first.coachPhoto,
        specialty: first.coachSpecialty ?? 'MMA',
        totalUsers: uniqueUsers.length,
        activeCount: rows
            .where((row) => row.effectiveDisplayStatus == 'active')
            .length,
        expiredCount: rows
            .where((row) => row.effectiveDisplayStatus == 'expired')
            .length,
      );
    }).toList()
      ..sort((a, b) => b.totalUsers.compareTo(a.totalUsers));
  }

  static List<SubscriberTrackingModel> buildSubscribers({
    required List<BookingHistoryModel> bookings,
    required Map<String, Map<String, String?>> profiles,
    String? coachId,
  }) {
    final scoped = coachId == null
        ? bookings
        : bookings.where((booking) => booking.coachId == coachId).toList();

    final grouped = <String, List<BookingHistoryModel>>{};
    for (final booking in scoped) {
      if (booking.userId.isEmpty) continue;
      grouped.putIfAbsent(booking.userId, () => []).add(booking);
    }

    return grouped.entries.map((entry) {
      final rows = entry.value;
      final profile = profiles[entry.key];
      final fullName = profile?['full_name']?.trim().isNotEmpty == true
          ? profile!['full_name']!.trim()
          : 'Unknown Member';
      final phone = profile?['phone'];
      final latest = rows
          .map((row) => row.createdAt)
          .whereType<DateTime>()
          .fold<DateTime?>(
            null,
            (previous, current) =>
                previous == null || current.isAfter(previous) ? current : previous,
          );

      return SubscriberTrackingModel(
        userId: entry.key,
        fullName: fullName,
        phone: phone,
        bookingCount: rows.length,
        activeCount: rows
            .where((row) => row.effectiveDisplayStatus == 'active')
            .length,
        expiredCount: rows
            .where((row) => row.effectiveDisplayStatus == 'expired')
            .length,
        latestBookingDate: latest,
        coachNames: rows.map((row) => row.coachName).toSet().toList(),
      );
    }).toList()
      ..sort((a, b) {
        final aDate = a.latestBookingDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.latestBookingDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
  }
}
