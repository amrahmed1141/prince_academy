import 'package:equatable/equatable.dart';
import 'package:prince_academy/features/admin/data/models/attendance_record_model.dart';
import 'package:prince_academy/features/booking/data/models/booking_history_model.dart';

class UserTrackingDetailModel extends Equatable {
  final String userId;
  final String fullName;
  final String? phone;
  final List<BookingHistoryModel> bookings;
  final List<AttendanceRecordModel> attendanceRecords;

  const UserTrackingDetailModel({
    required this.userId,
    required this.fullName,
    this.phone,
    required this.bookings,
    required this.attendanceRecords,
  });

  int get totalBookings => bookings.length;

  int get activeBookings =>
      bookings.where((b) => b.effectiveDisplayStatus == 'active').length;

  int get expiredBookings =>
      bookings.where((b) => b.effectiveDisplayStatus == 'expired').length;

  @override
  List<Object?> get props => [
        userId,
        fullName,
        phone,
        bookings,
        attendanceRecords,
      ];
}
