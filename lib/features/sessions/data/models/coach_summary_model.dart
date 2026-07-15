class CoachSummary {
  final String coachId;
  final String coachName;
  final String? coachPhoto;
  final String coachSpecialty;
  final int totalSessions;
  final int attendedSessions;
  final int remainingSessions;
  final bool activeBooking;

  CoachSummary({
    required this.coachId,
    required this.coachName,
    this.coachPhoto,
    required this.coachSpecialty,
    required this.totalSessions,
    required this.attendedSessions,
    required this.remainingSessions,
    required this.activeBooking,
  });

  factory CoachSummary.fromJson(Map<String, dynamic> json) => CoachSummary(
        coachId: json['coach_id']?.toString() ?? '',
        coachName: json['coach_name']?.toString() ?? 'Coach',
        coachPhoto: json['coach_photo']?.toString(),
        coachSpecialty: json['coach_specialty']?.toString() ?? '',
        totalSessions: (json['total_sessions'] as num?)?.toInt() ?? 0,
        attendedSessions:
            ((json['attended_sessions'] ?? json['completed_sessions']) as num?)
                    ?.toInt() ??
                0,
        remainingSessions: (json['remaining_sessions'] as num?)?.toInt() ?? 0,
        activeBooking: json['active_booking'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'coach_id': coachId,
        'coach_name': coachName,
        'coach_photo': coachPhoto,
        'coach_specialty': coachSpecialty,
        'total_sessions': totalSessions,
        'attended_sessions': attendedSessions,
        'remaining_sessions': remainingSessions,
        'active_booking': activeBooking,
      };
}
