import 'package:prince_academy/features/admin/data/models/coach_with_sessions.dart';
import 'package:prince_academy/features/admin/data/models/session_draft.dart';
import 'package:prince_academy/features/home/data/models/coach_session_model.dart';

abstract final class SessionDraftMapper {
  static SessionDraft fromCoachSession(CoachSessionModel session) {
    final rawSlots = CoachWithSessions.sessionSlotsFor(session);
    final slots = rawSlots
        .map(
          (entry) => SessionSlot(
            day: entry.day == '—' ? SessionSlot.defaultDay : entry.day,
            classType: entry.classType,
          ),
        )
        .toList();

    final sessionsPerWeek = session.sessionsPerWeek > 0
        ? session.sessionsPerWeek
        : (slots.isEmpty ? 1 : slots.length);

    final normalizedSlots = SessionDraft.resizeSlots(
      slots.isEmpty ? [SessionSlot.initial()] : slots,
      sessionsPerWeek,
    );

    return SessionDraft(
      coachId: session.coachId,
      branchId: session.branchId,
      timeSlot: session.timeSlots.isNotEmpty
          ? session.timeSlots.first
          : SessionDraft.defaultTimeSlot,
      pricePerSession: session.pricePerSession,
      sessionsPerWeek: sessionsPerWeek,
      sessions: normalizedSlots,
    );
  }
}
