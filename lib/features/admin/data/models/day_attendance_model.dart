class DayAttendance {
  final String dayName;
  final DateTime sessionDate;
  final String status;
  final bool isToday;

  const DayAttendance({
    required this.dayName,
    required this.sessionDate,
    required this.status,
    required this.isToday,
  });

  bool get isAttended => status.toLowerCase() == 'attended';

  factory DayAttendance.fromJson(Map<String, dynamic> json) {
    return DayAttendance(
      dayName: json['day_name'] as String? ?? '',
      sessionDate: _parseDate(json['session_date']) ?? DateTime.now(),
      status: json['status'] as String? ?? 'no_session',
      isToday: json['is_today'] as bool? ?? false,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
