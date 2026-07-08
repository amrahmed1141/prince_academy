import 'package:prince_academy/core/helpers/session_smart_defaults.dart';
import 'package:prince_academy/features/admin/data/models/branch_model.dart';
import 'package:prince_academy/features/admin/data/models/coach_model.dart';
import 'package:prince_academy/features/admin/data/models/session_draft.dart';
import 'package:prince_academy/features/home/data/models/coach_session_model.dart';

/// Applies session drafts and smart defaults to mutable admin form fields.
class AdminSessionFormSnapshot {
  const AdminSessionFormSnapshot({
    this.coachId,
    this.branchId,
    required this.timeSlot,
    required this.priceText,
    required this.sessionsPerWeek,
    required this.slots,
  });

  final String? coachId;
  final String? branchId;
  final String timeSlot;
  final String priceText;
  final int sessionsPerWeek;
  final List<SessionSlot> slots;

  factory AdminSessionFormSnapshot.fromDraft(SessionDraft draft) {
    return AdminSessionFormSnapshot(
      coachId: draft.coachId,
      branchId: draft.branchId,
      timeSlot: draft.timeSlot,
      priceText: draft.pricePerSession > 0
          ? draft.pricePerSession.toStringAsFixed(
              draft.pricePerSession == draft.pricePerSession.roundToDouble()
                  ? 0
                  : 2,
            )
          : '',
      sessionsPerWeek: draft.sessionsPerWeek,
      slots: List<SessionSlot>.from(draft.sessions),
    );
  }

  SessionDraft toDraft() {
    return SessionDraft(
      coachId: coachId,
      branchId: branchId,
      timeSlot: timeSlot,
      pricePerSession: double.tryParse(priceText.trim()) ?? 0,
      sessionsPerWeek: sessionsPerWeek,
      sessions: List<SessionSlot>.from(slots),
    );
  }
}

abstract final class AdminSessionFormHelper {
  static AdminSessionFormSnapshot resolveInitial({
    required List<CoachModel> coaches,
    required List<Branch> branches,
    required List<CoachSessionModel> sessions,
    SessionDraft? lastDraft,
    String? selectedCoachId,
    String? selectedBranchId,
    String? timeSlot,
    String? priceText,
    int? sessionsPerWeek,
    List<SessionSlot>? slots,
  }) {
    final base = SessionDraft(
      coachId: selectedCoachId ?? (coaches.isNotEmpty ? coaches.first.id : null),
      branchId: selectedBranchId ?? (branches.length == 1 ? branches.first.id : null),
      timeSlot: timeSlot ?? SessionDraft.defaultTimeSlot,
      pricePerSession: double.tryParse(priceText?.trim() ?? '') ?? 0,
      sessionsPerWeek: sessionsPerWeek ?? 1,
      sessions: slots ?? [SessionSlot.initial()],
    );

    CoachModel? coach;
    for (final item in coaches) {
      if (item.id == base.coachId) {
        coach = item;
        break;
      }
    }

    final resolved = SessionSmartDefaults.resolve(
      base: base,
      coach: coach,
      coachLatestSession: SessionSmartDefaults.latestSessionForCoach(
        base.coachId,
        sessions,
      ),
      lastDraft: lastDraft,
      singleBranchId: branches.length == 1 ? branches.first.id : null,
      restoreSlotSchedule: false,
    );

    return AdminSessionFormSnapshot.fromDraft(resolved);
  }

  static AdminSessionFormSnapshot forCoachChange({
    required String? coachId,
    required List<CoachModel> coaches,
    required List<CoachSessionModel> sessions,
    required AdminSessionFormSnapshot current,
    SessionDraft? lastDraft,
    String? singleBranchId,
  }) {
    CoachModel? coach;
    for (final item in coaches) {
      if (item.id == coachId) {
        coach = item;
        break;
      }
    }

    final resolved = SessionSmartDefaults.resolve(
      base: current.toDraft().copyWith(coachId: coachId),
      coach: coach,
      coachLatestSession: SessionSmartDefaults.latestSessionForCoach(
        coachId,
        sessions,
      ),
      lastDraft: lastDraft,
      singleBranchId: singleBranchId,
      restoreSlotSchedule: false,
    );

    return AdminSessionFormSnapshot.fromDraft(resolved);
  }

  static AdminSessionFormSnapshot afterSuccessfulSave({
    required SessionDraft savedDraft,
    required bool keepValues,
  }) {
    if (keepValues) {
      return AdminSessionFormSnapshot.fromDraft(savedDraft);
    }

    return AdminSessionFormSnapshot.fromDraft(
      savedDraft.copyWith(
        sessions: [SessionSlot.initial()],
        sessionsPerWeek: 1,
      ),
    );
  }
}
