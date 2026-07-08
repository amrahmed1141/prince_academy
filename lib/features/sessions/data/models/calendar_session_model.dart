class CalendarSessionModel {
  final DateTime sessionDate;
  final String? bookingId;
  final String? coachName;

  const CalendarSessionModel({
    required this.sessionDate,
    this.bookingId,
    this.coachName,
  });

  factory CalendarSessionModel.fromJson(Map<String, dynamic> json) {
    return CalendarSessionModel(
      sessionDate: _parseDate(json['session_date']) ?? DateTime.now(),
      bookingId: json['booking_id'] as String?,
      coachName: json['coach_name'] as String?,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
