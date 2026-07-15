import 'package:prince_academy/features/admin/data/models/coach_with_sessions.dart';
import 'package:prince_academy/features/admin/data/models/session_conflict_info.dart';
import 'package:prince_academy/features/admin/data/models/session_draft.dart';
import 'package:prince_academy/features/home/data/models/coach_session_model.dart';

/// Detects schedule conflicts when creating a coach session.
///
/// A conflict is another coach at the same branch with the same day,
/// class type, and time slot — even when that slot sits inside a
/// multi-day `session_type` pack (e.g. "MMA, Kickboxing, Fitness").
abstract final class SessionConflictDetector {
  static SessionConflictInfo? find({
    required SessionDraft draft,
    required List<CoachSessionModel> existingSessions,
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

    for (final session in existingSessions) {
      if (!session.isActive) continue;
      if (session.coachId == draftCoachId) continue;
      if (session.branchId != draftBranchId) continue;

      final sessionTime = session.timeSlots.isNotEmpty
          ? _normalizeTime(session.timeSlots.first)
          : '';
      if (sessionTime.isEmpty || sessionTime != draftTime) continue;

      final existingSlots = CoachWithSessions.sessionSlotsFor(session);

      for (final draftSlot in draft.sessions) {
        final draftDay = _normalizeDay(draftSlot.day);
        final draftType = _normalizeType(draftSlot.classType);
        if (draftDay.isEmpty || draftType.isEmpty) continue;

        for (final existingSlot in existingSlots) {
          if (_normalizeDay(existingSlot.day) != draftDay) continue;
          if (_normalizeType(existingSlot.classType) != draftType) continue;

          final name = session.coachName?.trim();
          return SessionConflictInfo(
            coachName: (name != null && name.isNotEmpty) ? name : 'Another coach',
          );
        }
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

  static String _normalizeType(String type) => type.trim().toLowerCase();

  static String _normalizeTime(String time) =>
      time.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
