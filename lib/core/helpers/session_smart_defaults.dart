import 'package:prince_academy/features/admin/data/models/coach_model.dart';
import 'package:prince_academy/features/admin/data/models/session_draft.dart';
import 'package:prince_academy/features/home/data/models/coach_session_model.dart';

/// Resolves sensible pre-fill values for the admin session form.
abstract final class SessionSmartDefaults {
  static const specialtyClassType = <String, String>{
    'Muay Thai': 'Striking',
    'BJJ': 'BJJ',
    'Wrestling': 'Wrestling',
    'Boxing': 'Boxing',
    'MMA': 'MMA',
    'Strength & Conditioning': 'Fitness',
  };

  static String classTypeForSpecialty(String? specialty) {
    if (specialty == null || specialty.trim().isEmpty) {
      return SessionSlot.defaultClassType;
    }
    return specialtyClassType[specialty.trim()] ?? SessionSlot.defaultClassType;
  }

  static CoachSessionModel? latestSessionForCoach(
    String? coachId,
    List<CoachSessionModel> sessions,
  ) {
    if (coachId == null || coachId.isEmpty) return null;
    for (final session in sessions) {
      if (session.coachId == coachId) return session;
    }
    return null;
  }

  /// Merges [base] with coach history, last saved draft, and branch context.
  ///
  /// When [restoreSlotSchedule] is false (initial form open), only scalar
  /// fields like branch/time/price are restored — slot count stays at [base].
  static SessionDraft resolve({
    required SessionDraft base,
    CoachModel? coach,
    CoachSessionModel? coachLatestSession,
    SessionDraft? lastDraft,
    String? singleBranchId,
    bool restoreSlotSchedule = false,
  }) {
    var draft = base;

    if (lastDraft != null) {
      draft = draft.copyWith(
        coachId: draft.coachId ?? lastDraft.coachId,
        branchId: draft.branchId ?? lastDraft.branchId,
        timeSlot: draft.timeSlot.isEmpty || draft.timeSlot == SessionDraft.defaultTimeSlot
            ? lastDraft.timeSlot
            : draft.timeSlot,
        pricePerSession: draft.pricePerSession > 0
            ? draft.pricePerSession
            : lastDraft.pricePerSession,
        sessionsPerWeek: restoreSlotSchedule && _hasOnlyInitialSlots(draft.sessions)
            ? lastDraft.sessionsPerWeek
            : draft.sessionsPerWeek,
        sessions: restoreSlotSchedule && _hasOnlyInitialSlots(draft.sessions)
            ? List<SessionSlot>.from(lastDraft.sessions)
            : draft.sessions,
      );
    }

    if (coachLatestSession != null) {
      final time = coachLatestSession.timeSlots.isNotEmpty
          ? coachLatestSession.timeSlots.first
          : draft.timeSlot;
      draft = draft.copyWith(
        branchId: draft.branchId ?? coachLatestSession.branchId,
        timeSlot: time.isNotEmpty ? time : draft.timeSlot,
        pricePerSession: draft.pricePerSession > 0
            ? draft.pricePerSession
            : coachLatestSession.pricePerSession,
      );
    }

    if (singleBranchId != null && (draft.branchId == null || draft.branchId!.isEmpty)) {
      draft = draft.copyWith(branchId: singleBranchId);
    }

    if (coach != null && _hasOnlyInitialSlots(draft.sessions)) {
      final classType = classTypeForSpecialty(coach.specialty);
      draft = draft.copyWith(
        sessions: draft.sessions
            .map((slot) => slot.copyWith(classType: classType))
            .toList(),
      );
    }

    if (draft.coachId == null && coach != null) {
      draft = draft.copyWith(coachId: coach.id);
    }

    return draft.copyWith(
      sessions: SessionDraft.resizeSlots(draft.sessions, draft.sessionsPerWeek),
    );
  }

  static bool _hasOnlyInitialSlots(List<SessionSlot> slots) {
    if (slots.isEmpty) return true;
    if (slots.length == 1) {
      final slot = slots.first;
      return slot.day == SessionSlot.defaultDay &&
          slot.classType == SessionSlot.defaultClassType;
    }
    return false;
  }
}
