class SessionDetail {
  final DateTime sessionDate;
  final String dayName;
  final String status;
  final bool isAttended;
  final bool canReAttend;
  final bool canUnmark;
  final String? sessionTime;

  const SessionDetail({
    required this.sessionDate,
    required this.dayName,
    required this.status,
    required this.isAttended,
    required this.canReAttend,
    this.canUnmark = false,
    this.sessionTime,
  });

  factory SessionDetail.fromJson(Map<String, dynamic> json) {
    return SessionDetail(
      sessionDate: _parseDate(json['session_date']) ?? DateTime.now(),
      dayName: json['day_name'] as String? ?? '',
      status: json['status'] as String? ?? 'upcoming',
      isAttended: json['is_attended'] as bool? ?? false,
      canReAttend: json['can_re_attend'] as bool? ?? false,
      canUnmark: json['can_unmark'] as bool? ?? false,
      sessionTime: json['session_time'] as String?,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  String get formattedDate {
    final local = sessionDate.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month';
  }
}
