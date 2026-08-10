import 'package:flutter_test/flutter_test.dart';
import 'package:prince_academy/features/sessions/data/models/session_model.dart';
import 'package:prince_academy/features/sessions/domain/weekly_progress_calculator.dart';

Session _session({
  required DateTime date,
  required String status,
  String? attendanceStatus,
  String bookingId = 'b1',
}) {
  return Session(
    bookingId: bookingId,
    coachId: 'c1',
    coachName: 'Coach',
    coachSpecialty: 'BJJ',
    selectedTime: '10:00',
    totalSessions: 8,
    attendedSessions: 0,
    remainingSessions: 8,
    sessionDate: date,
    dayName: 'Mon',
    isTrainingDay: true,
    sessionStatus: status,
    attendanceStatus: attendanceStatus,
  );
}

void main() {
  final today = DateTime(2026, 8, 10);
  final monday = DateTime(2026, 8, 10);
  final sunday = DateTime(2026, 8, 9);
  final tuesday = DateTime(2026, 8, 11);

  group('WeeklyProgressCalculator.daySessionAttendance', () {
    test('returns null when day has no sessions', () {
      final result = WeeklyProgressCalculator.daySessionAttendance(
        day: monday,
        sessions: const [],
        today: today,
      );
      expect(result, isNull);
    });

    test('returns null for future days even with sessions', () {
      final result = WeeklyProgressCalculator.daySessionAttendance(
        day: tuesday,
        sessions: [
          _session(date: tuesday, status: 'upcoming'),
        ],
        today: today,
      );
      expect(result, isNull);
    });

    test('attended all → ratio 1', () {
      final result = WeeklyProgressCalculator.daySessionAttendance(
        day: sunday,
        sessions: [
          _session(
            date: sunday,
            status: 'completed',
            attendanceStatus: 'attended',
            bookingId: 'a',
          ),
          _session(
            date: sunday,
            status: 'completed',
            attendanceStatus: 'attended',
            bookingId: 'b',
          ),
        ],
        today: today,
      );
      expect(result, isNotNull);
      expect(result!.attended, 2);
      expect(result.total, 2);
      expect(result.allAttended, isTrue);
      expect(result.ratio, 1.0);
    });

    test('partial → proportional ratio', () {
      final result = WeeklyProgressCalculator.daySessionAttendance(
        day: sunday,
        sessions: [
          _session(
            date: sunday,
            status: 'completed',
            attendanceStatus: 'attended',
            bookingId: 'a',
          ),
          _session(
            date: sunday,
            status: 'missed',
            bookingId: 'b',
          ),
        ],
        today: today,
      );
      expect(result, isNotNull);
      expect(result!.attended, 1);
      expect(result.total, 2);
      expect(result.ratio, 0.5);
      expect(result.allAttended, isFalse);
      expect(result.noneAttended, isFalse);
    });

    test('missed all → ratio 0', () {
      final result = WeeklyProgressCalculator.daySessionAttendance(
        day: sunday,
        sessions: [
          _session(date: sunday, status: 'missed', bookingId: 'a'),
        ],
        today: today,
      );
      expect(result, isNotNull);
      expect(result!.noneAttended, isTrue);
      expect(result.ratio, 0.0);
    });

    test('excludes frozen sessions from totals', () {
      final result = WeeklyProgressCalculator.daySessionAttendance(
        day: sunday,
        sessions: [
          _session(date: sunday, status: 'frozen', bookingId: 'a'),
          _session(
            date: sunday,
            status: 'completed',
            attendanceStatus: 'attended',
            bookingId: 'b',
          ),
        ],
        today: today,
      );
      expect(result, isNotNull);
      expect(result!.total, 1);
      expect(result.attended, 1);
      expect(result.allAttended, isTrue);
    });

    test('only frozen sessions → null (neutral circle)', () {
      final result = WeeklyProgressCalculator.daySessionAttendance(
        day: sunday,
        sessions: [
          _session(date: sunday, status: 'frozen', bookingId: 'a'),
        ],
        today: today,
      );
      expect(result, isNull);
    });
  });
}
