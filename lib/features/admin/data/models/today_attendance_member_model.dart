import 'package:equatable/equatable.dart';
import 'package:prince_academy/core/helpers/coach_photo_helper.dart';

/// One member expected on today's sessions (`today_attendance_members`).
class TodayAttendanceMember extends Equatable {
  const TodayAttendanceMember({
    required this.bookingId,
    required this.userId,
    required this.memberName,
    this.memberPhoto,
    required this.sessionId,
    required this.coachId,
    required this.coachName,
    this.coachPhoto,
    this.sessionType,
    this.sessionTime,
    this.branchName,
    this.isAttended = false,
  });

  final String bookingId;
  final String userId;
  final String memberName;
  final String? memberPhoto;
  final String sessionId;
  final String coachId;
  final String coachName;
  final String? coachPhoto;
  final String? sessionType;
  final String? sessionTime;
  final String? branchName;
  final bool isAttended;

  factory TodayAttendanceMember.fromJson(Map<String, dynamic> json) {
    return TodayAttendanceMember(
      bookingId: json['booking_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      memberName: (json['member_name'] as String?)?.trim().isNotEmpty == true
          ? (json['member_name'] as String).trim()
          : 'Member',
      memberPhoto: CoachPhotoHelper.normalize(json['member_photo'] as String?),
      sessionId: json['session_id'] as String? ?? '',
      coachId: json['coach_id'] as String? ?? '',
      coachName: (json['coach_name'] as String?)?.trim().isNotEmpty == true
          ? (json['coach_name'] as String).trim()
          : 'Coach',
      coachPhoto: CoachPhotoHelper.normalize(json['coach_photo'] as String?),
      sessionType: (json['session_type'] as String?)?.trim(),
      sessionTime: (json['session_time'] as String?)?.trim(),
      branchName: (json['branch_name'] as String?)?.trim(),
      isAttended: json['is_attended'] == true,
    );
  }

  TodayAttendanceMember copyWith({
    String? bookingId,
    String? userId,
    String? memberName,
    String? memberPhoto,
    String? sessionId,
    String? coachId,
    String? coachName,
    String? coachPhoto,
    String? sessionType,
    String? sessionTime,
    String? branchName,
    bool? isAttended,
  }) {
    return TodayAttendanceMember(
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      memberName: memberName ?? this.memberName,
      memberPhoto: memberPhoto ?? this.memberPhoto,
      sessionId: sessionId ?? this.sessionId,
      coachId: coachId ?? this.coachId,
      coachName: coachName ?? this.coachName,
      coachPhoto: coachPhoto ?? this.coachPhoto,
      sessionType: sessionType ?? this.sessionType,
      sessionTime: sessionTime ?? this.sessionTime,
      branchName: branchName ?? this.branchName,
      isAttended: isAttended ?? this.isAttended,
    );
  }

  @override
  List<Object?> get props => [
        bookingId,
        userId,
        memberName,
        memberPhoto,
        sessionId,
        coachId,
        coachName,
        coachPhoto,
        sessionType,
        sessionTime,
        branchName,
        isAttended,
      ];
}
