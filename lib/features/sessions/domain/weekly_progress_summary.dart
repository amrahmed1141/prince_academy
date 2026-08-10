import 'package:equatable/equatable.dart';

class WeeklyDayProgress extends Equatable {
  final DateTime date;
  final int expected;
  final int attended;

  const WeeklyDayProgress({
    required this.date,
    required this.expected,
    required this.attended,
  });

  double get fillRatio {
    if (expected <= 0) return attended > 0 ? 1.0 : 0.0;
    return (attended / expected).clamp(0.0, 1.0);
  }

  bool get hasExpected => expected > 0;

  @override
  List<Object?> get props => [date, expected, attended];
}

/// Per-day attended / total sessions for Member Home calendar day circles.
class DaySessionAttendance extends Equatable {
  final int attended;
  final int total;

  const DaySessionAttendance({
    required this.attended,
    required this.total,
  });

  double get ratio {
    if (total <= 0) return 0;
    return (attended / total).clamp(0.0, 1.0);
  }

  bool get allAttended => total > 0 && attended >= total;
  bool get noneAttended => total > 0 && attended <= 0;

  @override
  List<Object?> get props => [attended, total];
}

class WeeklyProgressSummary extends Equatable {
  final List<WeeklyDayProgress> days;
  final int totalExpected;
  final int totalAttended;
  final double weekRatio;
  final String performanceLabel;
  final String performanceHint;

  const WeeklyProgressSummary({
    required this.days,
    required this.totalExpected,
    required this.totalAttended,
    required this.weekRatio,
    required this.performanceLabel,
    required this.performanceHint,
  });

  static const empty = WeeklyProgressSummary(
    days: [],
    totalExpected: 0,
    totalAttended: 0,
    weekRatio: 0,
    performanceLabel: 'No sessions yet',
    performanceHint: 'Book a coach to start tracking',
  );

  @override
  List<Object?> get props => [
        days,
        totalExpected,
        totalAttended,
        weekRatio,
        performanceLabel,
        performanceHint,
      ];
}

enum BookingDisplayStatus {
  active,
  expired,
  completed,
  pending,
  pendingPayment,
  missed,
}

class TodaySessionInfo extends Equatable {
  final String coachName;
  final String time;
  final bool alreadyAttended;

  const TodaySessionInfo({
    required this.coachName,
    required this.time,
    this.alreadyAttended = false,
  });

  @override
  List<Object?> get props => [coachName, time, alreadyAttended];
}
