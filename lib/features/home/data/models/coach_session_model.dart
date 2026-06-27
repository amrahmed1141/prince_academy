class CoachSessionModel {
  final String id;
  final String coachId;
  final int sessionsPerWeek;
  final String sessionType;
  final List<String> days;
  final List<String> timeSlots;
  final double pricePerSession;
  final DateTime? sessionDate;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? coachName;
  final String? coachSpecialty;
  final String? coachPhotoUrl;
  final String? branchId;
  final String? branchName;

  CoachSessionModel({
    required this.id,
    required this.coachId,
    required this.sessionsPerWeek,
    required this.sessionType,
    this.days = const [],
    this.timeSlots = const [],
    this.pricePerSession = 0,
    this.sessionDate,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.coachName,
    this.coachSpecialty,
    this.coachPhotoUrl,
    this.branchId,
    this.branchName,
  });

  factory CoachSessionModel.fromJson(Map<String, dynamic> json) {
    final coachesData = json['coaches'];
    Map<String, dynamic>? coachMap;
    if (coachesData is Map<String, dynamic>) {
      coachMap = coachesData;
    }

    final branchesData = json['branches'];
    Map<String, dynamic>? branchMap;
    if (branchesData is Map<String, dynamic>) {
      branchMap = branchesData;
    }

    return CoachSessionModel(
      id: json['id'] as String? ?? '',
      coachId: json['coach_id'] as String? ?? '',
      sessionsPerWeek: json['sessions_per_week'] as int? ?? 0,
      sessionType: json['session_type'] as String? ?? '',
      days: _parseStringList(json['days']),
      timeSlots: _parseStringList(json['time_slots']),
      pricePerSession: (json['price_per_session'] as num?)?.toDouble() ?? 0,
      sessionDate: _parseDate(json['session_date']),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      coachName: coachMap?['name'] as String?,
      coachSpecialty: coachMap?['specialty'] as String?,
      coachPhotoUrl: coachMap?['photo_url'] as String?,
      branchId: json['branch_id'] as String?,
      branchName: json['branch_name'] as String? ?? branchMap?['name'] as String?,
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
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
      'days': days,
      'time_slots': timeSlots,
      'price_per_session': pricePerSession,
      'session_date': _formatDateForDb(sessionDate),
      'is_active': isActive,
    };
  }

  CoachSessionModel copyWith({
    String? id,
    String? coachId,
    int? sessionsPerWeek,
    String? sessionType,
    List<String>? days,
    List<String>? timeSlots,
    double? pricePerSession,
    DateTime? sessionDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? coachName,
    String? coachSpecialty,
    String? coachPhotoUrl,
    String? branchId,
    String? branchName,
  }) {
    return CoachSessionModel(
      id: id ?? this.id,
      coachId: coachId ?? this.coachId,
      sessionsPerWeek: sessionsPerWeek ?? this.sessionsPerWeek,
      sessionType: sessionType ?? this.sessionType,
      days: days ?? this.days,
      timeSlots: timeSlots ?? this.timeSlots,
      pricePerSession: pricePerSession ?? this.pricePerSession,
      sessionDate: sessionDate ?? this.sessionDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      coachName: coachName ?? this.coachName,
      coachSpecialty: coachSpecialty ?? this.coachSpecialty,
      coachPhotoUrl: coachPhotoUrl ?? this.coachPhotoUrl,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
    );
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
    if (days.isNotEmpty) return days.first;
    if (sessionDate == null) return null;
    const dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return dayNames[sessionDate!.toLocal().weekday - 1];
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'coach_id': coachId,
      'sessions_per_week': sessionsPerWeek,
      'session_type': sessionType,
      'days': days,
      'time_slots': timeSlots,
      'price_per_session': pricePerSession,
      'session_date': _formatDateForDb(sessionDate),
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
