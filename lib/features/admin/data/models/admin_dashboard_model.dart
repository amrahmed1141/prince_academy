import 'package:equatable/equatable.dart';
import 'package:prince_academy/core/helpers/coach_photo_helper.dart';
import 'package:prince_academy/features/admin/data/models/low_attendance_member_model.dart';
import 'package:prince_academy/features/admin/data/models/pending_payment_model.dart';

class AdminDashboardData extends Equatable {
  const AdminDashboardData({
    required this.pendingPaymentsCount,
    required this.pendingPaymentsPreview,
    required this.lowAttendancePreview,
    required this.todayRevenue,
    required this.activeMembersCount,
    required this.todaySessionsCount,
    required this.todaySessionsPreview,
    required this.coachesCount,
    required this.freezePendingCount,
  });

  final int pendingPaymentsCount;
  final List<PendingPaymentModel> pendingPaymentsPreview;
  final List<LowAttendanceMemberModel> lowAttendancePreview;
  final double todayRevenue;
  final int activeMembersCount;
  final int todaySessionsCount;
  final List<DashboardTodaySession> todaySessionsPreview;
  final int coachesCount;
  final int freezePendingCount;

  /// Sum of attended members across all of today's sessions.
  int get todayAttendedTotal => todaySessionsPreview.fold<int>(
        0,
        (sum, session) => sum + session.attendedCount,
      );

  /// Sum of booked capacity across all of today's sessions.
  int get todayBookedCapacity => todaySessionsPreview.fold<int>(
        0,
        (sum, session) => sum + session.bookedCount,
      );

  double get todayAttendanceProgress {
    if (todayBookedCapacity <= 0) return 0;
    return (todayAttendedTotal / todayBookedCapacity).clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => [
        pendingPaymentsCount,
        pendingPaymentsPreview,
        lowAttendancePreview,
        todayRevenue,
        activeMembersCount,
        todaySessionsCount,
        todaySessionsPreview,
        coachesCount,
        freezePendingCount,
      ];
}

/// One scheduled coach session for the current weekday (`today_coach_sessions`).
class DashboardTodaySession extends Equatable {
  const DashboardTodaySession({
    required this.sessionId,
    required this.coachId,
    required this.coachName,
    this.coachPhoto,
    this.sessionType,
    this.sessionTime,
    this.durationMinutes = 60,
    this.branchId,
    this.branchName,
    this.attendedCount = 0,
    this.bookedCount = 0,
  });

  final String sessionId;
  final String coachId;
  final String coachName;
  final String? coachPhoto;
  final String? sessionType;
  final String? sessionTime;
  final int durationMinutes;
  final String? branchId;
  final String? branchName;

  /// Members checked in today for this session (`attendance.status = attended`).
  final int attendedCount;

  /// Active verified bookings scheduled for this session today.
  final int bookedCount;

  String get attendanceRatioLabel => '$attendedCount/$bookedCount';

  double get attendanceProgress {
    if (bookedCount <= 0) return 0;
    return (attendedCount / bookedCount).clamp(0.0, 1.0);
  }

  factory DashboardTodaySession.fromJson(Map<String, dynamic> json) {
    final duration = (json['duration_minutes'] as num?)?.toInt() ?? 60;
    final attended = (json['attended_count'] as num?)?.toInt() ?? 0;
    final booked = (json['booked_count'] as num?)?.toInt() ?? 0;
    return DashboardTodaySession(
      sessionId: json['session_id'] as String? ?? '',
      coachId: json['coach_id'] as String? ?? '',
      coachName: json['coach_name'] as String? ?? 'Coach',
      coachPhoto: CoachPhotoHelper.normalize(json['coach_photo'] as String?),
      sessionType: (json['session_type'] as String?)?.trim(),
      sessionTime: (json['session_time'] as String?)?.trim() ??
          (json['selected_time'] as String?)?.trim(),
      durationMinutes: duration > 0 ? duration : 60,
      branchId: json['branch_id'] as String?,
      branchName: (json['branch_name'] as String?)?.trim(),
      attendedCount: attended < 0 ? 0 : attended,
      bookedCount: booked < 0 ? 0 : booked,
    );
  }

  @override
  List<Object?> get props => [
        sessionId,
        coachId,
        coachName,
        coachPhoto,
        sessionType,
        sessionTime,
        durationMinutes,
        branchId,
        branchName,
        attendedCount,
        bookedCount,
      ];
}
