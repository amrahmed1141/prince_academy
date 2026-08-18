import 'package:flutter_test/flutter_test.dart';
import 'package:prince_academy/features/booking/data/models/booking_history_model.dart';
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

BookingHistoryModel _booking({
  String id = 'b1',
  List<String> days = const ['Monday', 'Wednesday', 'Friday'],
  String displayStatus = 'active',
}) {
  return BookingHistoryModel(
    bookingId: id,
    userId: 'u1',
    coachId: 'c1',
    coachName: 'Coach',
    selectedDays: days,
    displayStatus: displayStatus,
    bookingStatus: displayStatus,
  );
}

void main() {
  // Week Sun 9 Aug – Sat 15 Aug 2026. Anchor Thursday 13 Aug.
  final thursday = DateTime(2026, 8, 13);
  final monday = DateTime(2026, 8, 10);
  final wednesday = DateTime(2026, 8, 12);
  final friday = DateTime(2026, 8, 14);

  group('WeeklyProgressCalculator.calculate', () {
    test('counts attended vs all scheduled sessions this week', () {
      final summary = WeeklyProgressCalculator.calculate(
        bookings: [_booking()],
        sessions: [
          _session(
            date: monday,
            status: 'completed',
            attendanceStatus: 'attended',
          ),
          _session(date: wednesday, status: 'missed'),
        ],
        anchor: thursday,
      );

      expect(summary.totalExpected, 3);
      expect(summary.totalAttended, 1);
      expect(summary.weekRatio, closeTo(1 / 3, 0.001));
    });

    test('includes upcoming scheduled sessions in the weekly total', () {
      final summary = WeeklyProgressCalculator.calculate(
        bookings: [_booking()],
        sessions: [
          _session(
            date: monday,
            status: 'completed',
            attendanceStatus: 'attended',
          ),
          _session(
            date: wednesday,
            status: 'completed',
            attendanceStatus: 'attended',
          ),
        ],
        anchor: thursday,
      );

      expect(summary.totalExpected, 3);
      expect(summary.totalAttended, 2);
      expect(
        summary.days.where((d) => d.date == friday).single.expected,
        1,
      );
    });

    test('ignores inactive bookings', () {
      final summary = WeeklyProgressCalculator.calculate(
        bookings: [_booking(displayStatus: 'expired')],
        sessions: [
          _session(
            date: monday,
            status: 'completed',
            attendanceStatus: 'attended',
          ),
        ],
        anchor: thursday,
      );

      expect(summary.totalExpected, 0);
      expect(summary.totalAttended, 0);
    });

    test('returns zero totals when nothing is scheduled', () {
      final summary = WeeklyProgressCalculator.calculate(
        bookings: const [],
        sessions: const [],
        anchor: thursday,
      );

      expect(summary.days, hasLength(7));
      expect(summary.totalExpected, 0);
      expect(summary.totalAttended, 0);
      expect(summary.weekRatio, 0);
    });
  });
}
