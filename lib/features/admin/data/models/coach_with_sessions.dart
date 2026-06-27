import 'package:prince_academy/features/home/data/models/coach_session_model.dart';

class CoachWithSessions {
  final String coachId;
  final String? branchId;
  final String? branchName;
  final String name;
  final String? photoUrl;
  final List<CoachSessionModel> schedules;

  const CoachWithSessions({
    required this.coachId,
    this.branchId,
    this.branchName,
    required this.name,
    this.photoUrl,
    required this.schedules,
  });

  bool get hasMultipleSchedules => schedules.length > 1;

  String get groupKey => '${coachId}_${branchId ?? 'none'}';

  static List<CoachWithSessions> group(List<CoachSessionModel> rows) {
    final grouped = <String, CoachWithSessions>{};

    for (final row in rows) {
      final key = '${row.coachId}_${row.branchId ?? 'none'}';

      if (!grouped.containsKey(key)) {
        grouped[key] = CoachWithSessions(
          coachId: row.coachId,
          branchId: row.branchId,
          branchName: row.branchName,
          name: row.coachName ?? 'Unknown Coach',
          photoUrl: row.coachPhotoUrl,
          schedules: [],
        );
      }

      final existing = grouped[key]!;
      grouped[key] = CoachWithSessions(
        coachId: existing.coachId,
        branchId: existing.branchId ?? row.branchId,
        branchName: existing.branchName ?? row.branchName,
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
