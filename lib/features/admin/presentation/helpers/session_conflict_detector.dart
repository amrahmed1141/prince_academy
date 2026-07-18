import 'package:prince_academy/features/admin/data/models/coach_with_sessions.dart';
import 'package:prince_academy/features/admin/data/models/session_conflict_info.dart';
import 'package:prince_academy/features/admin/data/models/session_draft.dart';
import 'package:prince_academy/features/home/data/models/coach_session_model.dart';

/// Detects schedule conflicts when creating/updating a coach session.
///
/// A conflict is another coach at the same branch with the same day and
/// time slot. Class type is ignored for matching.
abstract final class SessionConflictDetector {
  static SessionConflictInfo? find({
    required SessionDraft draft,
    required List<CoachSessionModel> existingSessions,
    String? excludeSessionId,
  }) {
    if (draft.branchId == null ||
        draft.branchId!.isEmpty ||
        draft.coachId == null ||
        draft.coachId!.isEmpty ||
        draft.sessions.isEmpty ||
        draft.timeSlot.trim().isEmpty) {
      return null;
    }

    final draftBranchId = draft.branchId!;
    final draftCoachId = draft.coachId!;
    final draftTime = _normalizeTime(draft.timeSlot);
    final draftDays = draft.sessions
        .map((slot) => _normalizeDay(slot.day))
        .where((day) => day.isNotEmpty)
        .toSet();

    if (draftDays.isEmpty) return null;

    for (final session in existingSessions) {
      if (!session.isActive) continue;
      if (excludeSessionId != null &&
          excludeSessionId.isNotEmpty &&
          session.id == excludeSessionId) {
        continue;
      }
      if (session.coachId == draftCoachId) continue;
      if (session.branchId != draftBranchId) continue;

      final rawTime = session.timeSlots.isNotEmpty
          ? session.timeSlots.first.trim()
          : '';
      final sessionTime = rawTime.isNotEmpty ? _normalizeTime(rawTime) : '';
      if (sessionTime.isEmpty || sessionTime != draftTime) continue;

      final existingSlots = CoachWithSessions.sessionSlotsFor(session);
      for (final existingSlot in existingSlots) {
        final existingDay = _normalizeDay(existingSlot.day);
        if (existingDay.isEmpty || !draftDays.contains(existingDay)) continue;

        final name = session.coachName?.trim();
        final fallbackTypes = session.sessionType
            .split(',')
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList();
        final classType = existingSlot.classType.trim().isNotEmpty
            ? existingSlot.classType.trim()
            : (fallbackTypes.isNotEmpty ? fallbackTypes.first : 'session');

        return SessionConflictInfo(
          coachName: (name != null && name.isNotEmpty) ? name : 'Another coach',
          classType: classType,
          timeSlot: rawTime.isNotEmpty ? rawTime : draft.timeSlot.trim(),
        );
      }
    }

    return null;
  }

  /// Friday / Fri / friday → fri
  static String _normalizeDay(String day) {
    final value = day.trim().toLowerCase();
    if (value.isEmpty || value == '—') return '';
    if (value.startsWith('mon')) return 'mon';
    if (value.startsWith('tue')) return 'tue';
    if (value.startsWith('wed')) return 'wed';
    if (value.startsWith('thu')) return 'thu';
    if (value.startsWith('fri')) return 'fri';
    if (value.startsWith('sat')) return 'sat';
    if (value.startsWith('sun')) return 'sun';
    return value.length >= 3 ? value.substring(0, 3) : value;
  }

  static String _normalizeTime(String time) =>
      time.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
