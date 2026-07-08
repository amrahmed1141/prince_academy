import 'package:prince_academy/features/admin/data/models/admin_scan_profile_model.dart';

List<AdminScanProfile> filterBookingsByStatus(
  List<AdminScanProfile> bookings,
  String? statusFilter,
) {
  if (statusFilter == 'active') {
    return bookings.where((b) => b.isActive).toList();
  }
  if (statusFilter == 'pending') {
    return bookings.where((b) => b.needsPaymentVerification).toList();
  }
  if (statusFilter == 'expired') {
    return bookings.where((b) {
      if (b.isActive || b.needsPaymentVerification) return false;
      return true;
    }).toList();
  }
  return bookings;
}

List<AdminScanProfile> pendingPaymentBookings(List<AdminScanProfile> bookings) =>
    bookings.where((b) => b.needsPaymentVerification).toList();

List<AdminScanProfile> sortMemberBookings(List<AdminScanProfile> bookings) {
  final sorted = List<AdminScanProfile>.from(bookings);
  sorted.sort((a, b) {
    final aToday = a.canMarkAttendanceToday ? 0 : 1;
    final bToday = b.canMarkAttendanceToday ? 0 : 1;
    if (aToday != bToday) return aToday.compareTo(bToday);

    final aActive = a.isActive ? 0 : 1;
    final bActive = b.isActive ? 0 : 1;
    if (aActive != bActive) return aActive.compareTo(bActive);

    return a.coachName.compareTo(b.coachName);
  });
  return sorted;
}

int countActiveBookings(List<AdminScanProfile> bookings) =>
    bookings.where((b) => b.isActive).length;

int countPendingBookings(List<AdminScanProfile> bookings) =>
    bookings.where((b) => b.needsPaymentVerification).length;

int countExpiredBookings(List<AdminScanProfile> bookings) => bookings
    .where((b) => !b.isActive && !b.needsPaymentVerification)
    .length;
