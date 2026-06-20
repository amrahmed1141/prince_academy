import 'package:prince_academy/features/home/data/models/coach_session_model.dart';

class CoachWithSessions {
  final String coachId;
  final String name;
  final String? photoUrl;
  final List<CoachSessionModel> schedules;

  const CoachWithSessions({
    required this.coachId,
    required this.name,
    this.photoUrl,
    required this.schedules,
  });

  bool get hasMultipleSchedules => schedules.length > 1;

  static List<CoachWithSessions> group(List<CoachSessionModel> rows) {
    final grouped = <String, CoachWithSessions>{};

    for (final row in rows) {
      if (!grouped.containsKey(row.coachId)) {
        grouped[row.coachId] = CoachWithSessions(
          coachId: row.coachId,
          name: row.coachName ?? 'Unknown Coach',
          photoUrl: row.coachPhotoUrl,
          schedules: [],
        );
      }

      final existing = grouped[row.coachId]!;
      grouped[row.coachId] = CoachWithSessions(
        coachId: existing.coachId,
        name: existing.name,
        photoUrl: existing.photoUrl ?? row.coachPhotoUrl,
        schedules: [...existing.schedules, row],
      );
    }

    return grouped.values.toList();
  }

  static List<({String day, String classType})> sessionSlotsFor(
    CoachSessionModel session,
  ) {
    final types = session.sessionType
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    if (session.days.isEmpty) {
      if (types.isEmpty) return const [];
      return types.map((type) => (day: '—', classType: type)).toList();
    }

    return List.generate(session.days.length, (index) {
      final day = session.days[index];
      final classType = index < types.length
          ? types[index]
          : (types.isNotEmpty ? types.first : session.sessionType);
      return (day: day, classType: classType);
    });
  }
}
