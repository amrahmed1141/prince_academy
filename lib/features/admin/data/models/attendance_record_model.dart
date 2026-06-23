import 'package:equatable/equatable.dart';

class AttendanceRecordModel extends Equatable {
  final String id;
  final String bookingId;
  final String userId;
  final String coachId;
  final String? coachName;
  final DateTime attendedOn;
  final String status;

  const AttendanceRecordModel({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.coachId,
    this.coachName,
    required this.attendedOn,
    required this.status,
  });

  bool get isAttended => status.toLowerCase() == 'attended';

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    final coaches = json['coaches'];
    String? coachName;
    if (coaches is Map<String, dynamic>) {
      coachName = coaches['name'] as String?;
    }

    return AttendanceRecordModel(
      id: json['id'] as String? ?? '',
      bookingId: json['booking_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      coachId: json['coach_id'] as String? ?? '',
      coachName: coachName,
      attendedOn: _parseDate(json['attended_on']) ?? DateTime.now(),
      status: json['status'] as String? ?? 'attended',
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  @override
  List<Object?> get props => [
        id,
        bookingId,
        userId,
        coachId,
        coachName,
        attendedOn,
        status,
      ];
}
