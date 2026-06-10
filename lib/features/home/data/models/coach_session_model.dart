class CoachSessionModel {
  final String id;
  final String coachId;
  final int sessionsPerWeek;
  final String sessionType;
  final DateTime? sessionDate;
  final bool isActive;

  CoachSessionModel({
    required this.id,
    required this.coachId,
    required this.sessionsPerWeek,
    required this.sessionType,
    this.sessionDate,
    required this.isActive,
  });

  factory CoachSessionModel.fromMap(Map<String, dynamic> map) {
    return CoachSessionModel(
      id: map['id'] as String? ?? '',
      coachId: map['coach_id'] as String? ?? '',
      sessionsPerWeek: map['sessions_per_week'] as int? ?? 0,
      sessionType: map['session_type'] as String? ?? '',
      sessionDate: map['session_date'] != null ? DateTime.tryParse(map['session_date'] as String) : null,
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'coach_id': coachId,
      'sessions_per_week': sessionsPerWeek,
      'session_type': sessionType,
      'session_date': sessionDate?.toIso8601String(),
      'is_active': isActive,
    };
  }
}
