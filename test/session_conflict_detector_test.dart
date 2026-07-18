import 'package:flutter_test/flutter_test.dart';
import 'package:prince_academy/features/admin/data/models/session_draft.dart';
import 'package:prince_academy/features/admin/presentation/helpers/session_conflict_detector.dart';
import 'package:prince_academy/features/home/data/models/coach_session_model.dart';

void main() {
  test('flags same branch + day + time even when class types differ', () {
    final draft = SessionDraft(
      coachId: 'testt-id',
      branchId: 'elzaiton-id',
      timeSlot: '8:00 PM',
      pricePerSession: 500,
      sessionsPerWeek: 1,
      sessions: const [
        SessionSlot(day: 'Friday', classType: 'Fitness'),
      ],
    );

    final existing = [
      CoachSessionModel(
        id: 'kareem-session',
        coachId: 'kareem-id',
        sessionsPerWeek: 2,
        sessionType: 'Boxing, Wrestling',
        days: const ['Thursday', 'Friday'],
        timeSlots: const ['8:00 PM'],
        isActive: true,
        coachName: 'kareem',
        branchId: 'elzaiton-id',
        branchName: 'ElZaiton Branch',
      ),
    ];

    final conflict = SessionConflictDetector.find(
      draft: draft,
      existingSessions: existing,
    );

    expect(conflict, isNotNull);
    expect(conflict!.coachName, 'kareem');
    expect(conflict.classType, 'Wrestling');
    expect(conflict.timeSlot, '8:00 PM');
    expect(
      conflict.message,
      'There is already a Wrestling session at this time with coach kareem at 8:00 PM',
    );
  });
}
