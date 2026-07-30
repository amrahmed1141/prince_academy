import 'package:equatable/equatable.dart';
import 'package:prince_academy/core/helpers/coach_photo_helper.dart';

class LowAttendanceCoachProgress extends Equatable {
  const LowAttendanceCoachProgress({
    required this.coachId,
    required this.coachName,
    required this.attendedCount,
    required this.totalCount,
    required this.missedCount,
    this.attendanceRate,
  });

  final String coachId;
  final String coachName;
  final int attendedCount;
  final int totalCount;
  final int missedCount;
  final double? attendanceRate;

  String get ratioLabel => '$attendedCount/$totalCount';

  String get missedSessionsLabel {
    final count =
        missedCount > 0 ? missedCount : (totalCount - attendedCount);
    final label = count == 1 ? 'missed session' : 'missed sessions';
    return '$count $label';
  }

  String get withCoachLabel => 'with $coachName';

  double get progress {
    if (totalCount <= 0) return 0;
    return (attendedCount / totalCount).clamp(0.0, 1.0);
  }

  factory LowAttendanceCoachProgress.fromJson(Map<String, dynamic> json) {
    final rate = json['attendance_rate'];
    final attended = (json['attended_count'] as num?)?.toInt() ?? 0;
    final total = (json['total_count'] as num?)?.toInt() ?? 0;
    return LowAttendanceCoachProgress(
      coachId: json['coach_id'] as String? ?? '',
      coachName: json['coach_name'] as String? ?? 'Coach',
      attendedCount: attended,
      totalCount: total,
      missedCount: (json['missed_count'] as num?)?.toInt() ??
          (total - attended).clamp(0, total),
      attendanceRate: rate is num ? rate.toDouble() : double.tryParse('$rate'),
    );
  }

  @override
  List<Object?> get props => [
        coachId,
        coachName,
        attendedCount,
        totalCount,
        missedCount,
        attendanceRate,
      ];
}

class LowAttendanceMemberModel extends Equatable {
  const LowAttendanceMemberModel({
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    this.coaches = const [],
  });

  final String userId;
  final String fullName;
  final String? avatarUrl;
  final List<LowAttendanceCoachProgress> coaches;

  factory LowAttendanceMemberModel.fromJson(Map<String, dynamic> json) {
    final rawCoaches = json['coaches'];
    final coaches = <LowAttendanceCoachProgress>[];

    if (rawCoaches is List) {
      for (final item in rawCoaches) {
        if (item is Map) {
          coaches.add(
            LowAttendanceCoachProgress.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    if (coaches.isEmpty) {
      final attended = (json['attended_count'] as num?)?.toInt() ?? 0;
      final expected = (json['expected_count'] as num?)?.toInt() ?? 0;
      if (expected > 0) {
        final rate = json['attendance_rate'];
        coaches.add(
          LowAttendanceCoachProgress(
            coachId: '',
            coachName: 'All coaches',
            attendedCount: attended,
            totalCount: expected,
            missedCount: (expected - attended).clamp(0, expected),
            attendanceRate:
                rate is num ? rate.toDouble() : double.tryParse('$rate'),
          ),
        );
      }
    }

    return LowAttendanceMemberModel(
      userId: json['user_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Member',
      avatarUrl: CoachPhotoHelper.normalize(json['avatar_url'] as String?),
      coaches: coaches,
    );
  }

  @override
  List<Object?> get props => [userId, fullName, avatarUrl, coaches];
}
