class CoachSessionModel {
  final String id;
  final String coachId;
  final int sessionsPerWeek;
  final String sessionType;
  final DateTime? sessionDate;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? coachName;
  final String? coachSpecialty;
  final String? coachPhotoUrl;

  CoachSessionModel({
    required this.id,
    required this.coachId,
    required this.sessionsPerWeek,
    required this.sessionType,
    this.sessionDate,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.coachName,
    this.coachSpecialty,
    this.coachPhotoUrl,
  });

  factory CoachSessionModel.fromJson(Map<String, dynamic> json) {
    final coachesData = json['coaches'];
    Map<String, dynamic>? coachMap;
    if (coachesData is Map<String, dynamic>) {
      coachMap = coachesData;
    }

    return CoachSessionModel(
      id: json['id'] as String? ?? '',
      coachId: json['coach_id'] as String? ?? '',
      sessionsPerWeek: json['sessions_per_week'] as int? ?? 0,
      sessionType: json['session_type'] as String? ?? '',
      sessionDate: _parseDate(json['session_date']),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      coachName: coachMap?['name'] as String?,
      coachSpecialty: coachMap?['specialty'] as String?,
      coachPhotoUrl: coachMap?['photo_url'] as String?,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  factory CoachSessionModel.fromMap(Map<String, dynamic> map) {
    return CoachSessionModel.fromJson(map);
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'coach_id': coachId,
      'sessions_per_week': sessionsPerWeek,
      'session_type': sessionType,
      'session_date': _formatDateForDb(sessionDate),
      'is_active': isActive,
    };
  }

  static String? _formatDateForDb(DateTime? date) {
    if (date == null) return null;
    final local = date.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String? get formattedSessionDate {
    if (sessionDate == null) return null;
    final date = sessionDate!.toLocal();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String? get weekdayLabel {
    if (sessionDate == null) return null;
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[sessionDate!.toLocal().weekday - 1];
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'coach_id': coachId,
      'sessions_per_week': sessionsPerWeek,
      'session_type': sessionType,
      'session_date': _formatDateForDb(sessionDate),
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
