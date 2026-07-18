class Session {
  final String bookingId;
  final String coachId;
  final String coachName;
  final String? coachPhoto;
  final String coachSpecialty;
  final String? branchName;
  final String selectedTime;
  final int totalSessions;
  final int attendedSessions;
  final int remainingSessions;
  final DateTime sessionDate;
  final String dayName;
  final bool isTrainingDay;
  final String sessionStatus;
  final String? attendanceStatus;

  Session({
    required this.bookingId,
    required this.coachId,
    required this.coachName,
    this.coachPhoto,
    required this.coachSpecialty,
    this.branchName,
    required this.selectedTime,
    required this.totalSessions,
    required this.attendedSessions,
    required this.remainingSessions,
    required this.sessionDate,
    required this.dayName,
    required this.isTrainingDay,
    required this.sessionStatus,
    this.attendanceStatus,
  });

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        bookingId: json['booking_id']?.toString() ?? '',
        coachId: json['coach_id']?.toString() ?? '',
        coachName: json['coach_name']?.toString() ?? 'Coach',
        coachPhoto: json['coach_photo']?.toString(),
        coachSpecialty: json['coach_specialty']?.toString() ?? '',
        branchName: json['branch_name']?.toString(),
        selectedTime: json['selected_time']?.toString() ?? '',
        totalSessions: (json['total_sessions'] as num?)?.toInt() ?? 0,
        attendedSessions:
            ((json['attended_sessions'] ?? json['completed_sessions']) as num?)
                    ?.toInt() ??
                0,
        remainingSessions: (json['remaining_sessions'] as num?)?.toInt() ?? 0,
        sessionDate: _parseSessionDate(json['session_date']),
        dayName: json['day_name']?.toString() ?? '',
        isTrainingDay: json['is_training_day'] as bool? ?? true,
        sessionStatus: json['session_status']?.toString() ?? 'upcoming',
        attendanceStatus: json['attendance_status']?.toString(),
      );

  static DateTime _parseSessionDate(dynamic raw) {
    final parsed = DateTime.tryParse(raw?.toString() ?? '') ?? DateTime.now();
    final local = parsed.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  Map<String, dynamic> toJson() => {
        'booking_id': bookingId,
        'coach_id': coachId,
        'coach_name': coachName,
        'coach_photo': coachPhoto,
        'coach_specialty': coachSpecialty,
        'branch_name': branchName,
        'selected_time': selectedTime,
        'total_sessions': totalSessions,
        'attended_sessions': attendedSessions,
        'remaining_sessions': remainingSessions,
        'session_date': sessionDate.toIso8601String(),
        'day_name': dayName,
        'is_training_day': isTrainingDay,
        'session_status': sessionStatus,
        'attendance_status': attendanceStatus,
      };

  bool get isCompleted => sessionStatus == 'completed';
  bool get isToday => sessionStatus == 'today';
  bool get isUpcoming => sessionStatus == 'upcoming';
  bool get isMissed => sessionStatus == 'missed';
}
