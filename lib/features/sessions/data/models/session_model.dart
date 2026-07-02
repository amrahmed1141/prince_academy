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
        sessionDate: DateTime.parse(json['session_date'].toString()),
        dayName: json['day_name']?.toString() ?? '',
        isTrainingDay: json['is_training_day'] as bool? ?? true,
        sessionStatus: json['session_status']?.toString() ?? 'upcoming',
        attendanceStatus: json['attendance_status']?.toString(),
      );

  bool get isCompleted => sessionStatus == 'completed';
  bool get isToday => sessionStatus == 'today';
  bool get isUpcoming => sessionStatus == 'upcoming';
  bool get isMissed => sessionStatus == 'missed';
}
