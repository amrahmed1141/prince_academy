# Tests excerpts

## A. Helper unit test

SOURCE: `test/session_conflict_detector_test.dart`  
Subject: `lib/features/admin/presentation/helpers/session_conflict_detector.dart`

```dart
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
    expect(
      conflict.message,
      'There is already a Wrestling session at this time with coach kareem at 8:00 PM',
    );
  });
}
```

## B. Model / paging unit test

SOURCE: `test/paged_result_test.dart`

```dart
void main() {
  group('PagedResult hasMore', () {
    test('full page keeps hasMore true', () {
      final page = PagedResult<ActiveUser>(
        items: List.generate(
          50,
          (i) => ActiveUser(
            userId: 'u$i',
            fullName: 'User $i',
            totalBookings: 1,
            activeBookings: 1,
            expiredBookings: 0,
          ),
        ),
        hasMore: true,
        totalCount: 120,
      );

      expect(page.items.length, 50);
      expect(page.hasMore, isTrue);
      expect(page.totalCount, 120);
    });

    test('hasMore derived from page length vs page size', () {
      bool computeHasMore(int pageLength, int pageSize) =>
          pageLength >= pageSize;

      expect(computeHasMore(50, 50), isTrue);
      expect(computeHasMore(20, 50), isFalse);
    });
  });
}
```

## Suggested next (from testing guide — not yet present)

When adding BLoC/Cubit tests: mock the repository via constructor injection, keep tests under `test/` with `flutter_test`, mirroring `lib/` paths. Do not invent a new test stack.
