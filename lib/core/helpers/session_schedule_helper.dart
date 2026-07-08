import 'package:intl/intl.dart';

/// Generates subscription session dates client-side (mirrors backend logic).
class SessionScheduleHelper {
  SessionScheduleHelper._();

  static const _dayToWeekday = {
    'mon': DateTime.monday,
    'monday': DateTime.monday,
    'tue': DateTime.tuesday,
    'tuesday': DateTime.tuesday,
    'wed': DateTime.wednesday,
    'wednesday': DateTime.wednesday,
    'thu': DateTime.thursday,
    'thursday': DateTime.thursday,
    'fri': DateTime.friday,
    'friday': DateTime.friday,
    'sat': DateTime.saturday,
    'saturday': DateTime.saturday,
    'sun': DateTime.sunday,
    'sunday': DateTime.sunday,
  };

  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Subscription end = start + exactly 1 calendar month.
  static DateTime subscriptionEndDate(DateTime startDate) {
    final start = dateOnly(startDate);
    return DateTime(start.year, start.month + 1, start.day);
  }

  static Set<int> _weekdaysFromDays(List<String> days) {
    final result = <int>{};
    for (final day in days) {
      final key = day.toLowerCase().trim();
      final short = key.length >= 3 ? key.substring(0, 3) : key;
      final weekday = _dayToWeekday[key] ?? _dayToWeekday[short];
      if (weekday != null) result.add(weekday);
    }
    return result;
  }

  /// All session dates from [startDate] (inclusive) until subscription end (exclusive).
  static List<DateTime> generateSessionDates({
    required DateTime startDate,
    required List<String> selectedDays,
  }) {
    if (selectedDays.isEmpty) return [];

    final start = dateOnly(startDate);
    final end = subscriptionEndDate(start);
    final weekdays = _weekdaysFromDays(selectedDays);
    if (weekdays.isEmpty) return [];

    final dates = <DateTime>[];
    var current = start;
    while (current.isBefore(end)) {
      if (weekdays.contains(current.weekday)) {
        dates.add(current);
      }
      current = current.add(const Duration(days: 1));
    }
    return dates;
  }

  static String formatPeriod(DateTime start, DateTime end) {
    final fmt = DateFormat('MMM d');
    return '${fmt.format(start)} → ${fmt.format(end)}';
  }

  static String formatPeriodWithMonth(DateTime start, DateTime end) {
    return '${formatPeriod(start, end)} (1 month)';
  }

  static String formatSessionPreview(DateTime date, String time, int index) {
    final dayFmt = DateFormat('EEE, MMM d');
    return 'Session ${index + 1}: ${dayFmt.format(date)} · $time';
  }

  static String formatDateForDb(DateTime date) {
    final local = dateOnly(date);
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// True when [onDate] falls on a selected training day within the subscription window.
  static bool isSessionDayOnDate({
    required List<String> selectedDays,
    required DateTime? subscriptionStart,
    required DateTime? subscriptionEnd,
    DateTime? onDate,
  }) {
    if (selectedDays.isEmpty ||
        subscriptionStart == null ||
        subscriptionEnd == null) {
      return false;
    }

    final date = dateOnly(onDate ?? DateTime.now());
    final start = dateOnly(subscriptionStart);
    final end = dateOnly(subscriptionEnd);
    if (date.isBefore(start) || date.isAfter(end)) return false;

    final weekdays = _weekdaysFromDays(selectedDays);
    return weekdays.contains(date.weekday);
  }
}
