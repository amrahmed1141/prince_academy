class SessionSlot {
  final String day;
  final String classType;

  const SessionSlot({
    required this.day,
    required this.classType,
  });

  static const defaultDay = 'Monday';
  static const defaultClassType = 'Striking';

  factory SessionSlot.initial() {
    return const SessionSlot(
      day: defaultDay,
      classType: defaultClassType,
    );
  }

  factory SessionSlot.fromJson(Map<String, dynamic> json) {
    return SessionSlot(
      day: json['day'] as String? ?? defaultDay,
      classType: json['class_type'] as String? ?? defaultClassType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'class_type': classType,
    };
  }

  SessionSlot copyWith({
    String? day,
    String? classType,
  }) {
    return SessionSlot(
      day: day ?? this.day,
      classType: classType ?? this.classType,
    );
  }
}

class SessionDraft {
  final String? coachId;
  final String? branchId;
  final String timeSlot;
  final double pricePerSession;
  final int sessionsPerWeek;
  final List<SessionSlot> sessions;

  const SessionDraft({
    this.coachId,
    this.branchId,
    required this.timeSlot,
    required this.pricePerSession,
    required this.sessionsPerWeek,
    required this.sessions,
  });

  static const defaultTimeSlot = '8:00 AM';

  static const presetTimeSlots = [
    '7:00 AM',
    '8:00 AM',
    '9:00 AM',
    '10:00 AM',
    '5:00 PM',
    '6:00 PM',
    '7:00 PM',
    '8:00 PM',
  ];

  static const weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const classTypes = [
    'Striking',
    'Grappling',
    'BJJ',
    'MMA',
    'Boxing',
    'Wrestling',
    'Kickboxing',
    'Fitness',
  ];

  factory SessionDraft.initial({String? coachId, String? branchId}) {
    return SessionDraft(
      coachId: coachId,
      branchId: branchId,
      timeSlot: defaultTimeSlot,
      pricePerSession: 0,
      sessionsPerWeek: 1,
      sessions: [SessionSlot.initial()],
    );
  }

  factory SessionDraft.fromJson(Map<String, dynamic> json) {
    final rawSessions = json['sessions'];
    final parsedSessions = rawSessions is List
        ? rawSessions
            .map(
              (e) => SessionSlot.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList()
        : <SessionSlot>[SessionSlot.initial()];

    return SessionDraft(
      coachId: json['coach_id'] as String?,
      branchId: json['branch_id'] as String?,
      timeSlot: json['time_slot'] as String? ?? defaultTimeSlot,
      pricePerSession: (json['price_per_session'] as num?)?.toDouble() ?? 0,
      sessionsPerWeek: json['sessions_per_week'] as int? ?? 1,
      sessions: parsedSessions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (coachId != null) 'coach_id': coachId,
      if (branchId != null) 'branch_id': branchId,
      'time_slot': timeSlot,
      'price_per_session': pricePerSession,
      'sessions_per_week': sessionsPerWeek,
      'sessions': sessions.map((s) => s.toJson()).toList(),
      'days': sessions.map((s) => s.day).toList(),
      'time_slots': [timeSlot],
      'session_type': sessions.map((s) => s.classType).join(', '),
      'is_active': true,
    };
  }

  SessionDraft copyWith({
    String? coachId,
    String? branchId,
    String? timeSlot,
    double? pricePerSession,
    int? sessionsPerWeek,
    List<SessionSlot>? sessions,
  }) {
    return SessionDraft(
      coachId: coachId ?? this.coachId,
      branchId: branchId ?? this.branchId,
      timeSlot: timeSlot ?? this.timeSlot,
      pricePerSession: pricePerSession ?? this.pricePerSession,
      sessionsPerWeek: sessionsPerWeek ?? this.sessionsPerWeek,
      sessions: sessions ?? this.sessions,
    );
  }

  static List<SessionSlot> resizeSlots(List<SessionSlot> current, int count) {
    if (count <= 0) return [];
    if (current.length == count) return List.from(current);
    if (current.length > count) return current.sublist(0, count);
    return [
      ...current,
      ...List.generate(
        count - current.length,
        (_) => SessionSlot.initial(),
      ),
    ];
  }
}
