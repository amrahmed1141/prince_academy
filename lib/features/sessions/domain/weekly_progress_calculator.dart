import 'package:prince_academy/core/helpers/subscription_formatters.dart';
import 'package:prince_academy/features/booking/data/models/booking_history_model.dart';
import 'package:prince_academy/features/sessions/data/models/session_model.dart';
import 'package:prince_academy/features/sessions/domain/weekly_progress_summary.dart';

class WeeklyProgressCalculator {
  WeeklyProgressCalculator._();

  static List<DateTime> weekDaysStartingSunday(DateTime anchor) {
    final local = anchor.toLocal();
    final sunday = local.subtract(Duration(days: local.weekday % 7));
    final start = DateTime(sunday.year, sunday.month, sunday.day);
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  static bool isSameDay(DateTime a, DateTime b) {
    final al = a.toLocal();
    final bl = b.toLocal();
    return al.year == bl.year && al.month == bl.month && al.day == bl.day;
  }

  static bool isScheduledOnDay(DateTime date, List<String> selectedDays) {
    if (selectedDays.isEmpty) return false;
    final full = SubscriptionFormatters.weekdayName(date);
    final short = full.substring(0, 3);
    return selectedDays.any((raw) {
      final day = raw.toLowerCase().trim();
      if (day.isEmpty) return false;
      return day == full.toLowerCase() ||
          day == short.toLowerCase() ||
          day.startsWith(short.toLowerCase()) ||
          short.toLowerCase().startsWith(day.substring(0, day.length.clamp(0, 3)));
    });
  }

  static bool isBookingSchedulable(BookingHistoryModel booking, DateTime date) {
    if (resolveDisplayStatus(booking) != BookingDisplayStatus.active) {
      return false;
    }
    return _isWithinSubscription(booking, date) &&
        isScheduledOnDay(date, booking.selectedDays);
  }

  static bool _isWithinSubscription(BookingHistoryModel booking, DateTime date) {
    final start = booking.subscriptionStart;
    final end = booking.subscriptionEnd;
    if (start == null || end == null) return true;
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return !d.isBefore(s) && !d.isAfter(e);
  }

  static bool isSessionAttended(Session session) {
    return session.isCompleted ||
        session.attendanceStatus?.toLowerCase() == 'attended';
  }

  static BookingDisplayStatus resolveDisplayStatus(BookingHistoryModel booking) {
    // Use display_status from the view — do not override pending with active.
    final status = booking.displayStatus.toLowerCase();

    if (booking.totalSessions > 0 &&
        booking.attendedSessions >= booking.totalSessions) {
      return BookingDisplayStatus.completed;
    }
    if (status == 'pending_payment' || status == 'awaiting_verification') {
      return BookingDisplayStatus.pendingPayment;
    }
    if (status == 'expired') return BookingDisplayStatus.expired;
    if (status == 'missed') return BookingDisplayStatus.missed;
    if (status == 'pending') return BookingDisplayStatus.pending;
    if (status == 'active' || status == 'completed') {
      return status == 'completed'
          ? BookingDisplayStatus.completed
          : BookingDisplayStatus.active;
    }
    return BookingDisplayStatus.pending;
  }

  static Session? todaySessionRecordForBooking(
    BookingHistoryModel booking,
    List<Session> sessions,
  ) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    for (final session in sessions) {
      if (session.bookingId != booking.bookingId) continue;
      if (isSameDay(session.sessionDate, todayDate) ||
          session.isToday ||
          session.sessionStatus.toLowerCase() == 'today') {
        return session;
      }
    }
    return null;
  }

  static TodaySessionInfo? todaySessionForBooking(
    BookingHistoryModel booking,
    List<Session> sessions,
  ) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    if (resolveDisplayStatus(booking) != BookingDisplayStatus.active) {
      return null;
    }

    if (!isScheduledOnDay(todayDate, booking.selectedDays) ||
        !_isWithinSubscription(booking, todayDate)) {
      return null;
    }

    final match = todaySessionRecordForBooking(booking, sessions);
    if (match == null) return null;

    final time = booking.selectedTime?.trim().isNotEmpty == true
        ? booking.selectedTime!.trim()
        : match.selectedTime.trim().isNotEmpty
            ? match.selectedTime
            : 'Time TBD';

    return TodaySessionInfo(
      coachName: booking.coachName,
      time: time,
      alreadyAttended: isSessionAttended(match),
    );
  }

  static WeeklyProgressSummary calculate({
    required List<BookingHistoryModel> bookings,
    required List<Session> sessions,
    DateTime? anchor,
  }) {
    final now = anchor ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekDays = weekDaysStartingSunday(now);

    final days = <WeeklyDayProgress>[];
    var totalExpected = 0;
    var totalAttended = 0;

    for (final day in weekDays) {
      if (day.isAfter(today)) {
        days.add(WeeklyDayProgress(date: day, expected: 0, attended: 0));
        continue;
      }

      final expected = bookings
          .where((b) => isBookingSchedulable(b, day))
          .length;

      final attended = sessions.where((session) {
        if (!isSameDay(session.sessionDate, day)) return false;
        if (!isSessionAttended(session)) return false;
        return bookings.any((b) => b.bookingId == session.bookingId);
      }).length;

      days.add(
        WeeklyDayProgress(date: day, expected: expected, attended: attended),
      );

      if (expected > 0) {
        totalExpected += expected;
        totalAttended += attended.clamp(0, expected);
      }
    }

    final ratio =
        totalExpected > 0 ? (totalAttended / totalExpected).clamp(0.0, 1.0) : 0.0;
    final (label, hint) = _performanceCopy(ratio, totalExpected);

    return WeeklyProgressSummary(
      days: days,
      totalExpected: totalExpected,
      totalAttended: totalAttended,
      weekRatio: ratio,
      performanceLabel: label,
      performanceHint: hint,
    );
  }

  static (String, String) _performanceCopy(double ratio, int expected) {
    if (expected == 0) {
      return ('No sessions this week', 'Your schedule starts soon');
    }
    if (ratio >= 0.9) {
      return ('Excellent', 'You hit nearly all your sessions this week');
    }
    if (ratio >= 0.7) {
      return ('Good', 'Solid week — keep the momentum going');
    }
    if (ratio >= 0.4) {
      return ('Keep training', 'A few more sessions will boost your progress');
    }
    return ('Need to train more', 'Try to catch up on missed sessions');
  }
}
