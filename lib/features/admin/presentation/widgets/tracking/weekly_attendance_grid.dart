import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/data/models/day_attendance_model.dart';

class WeeklyAttendanceGrid extends StatelessWidget {
  final List<DayAttendance> days;

  const WeeklyAttendanceGrid({
    super.key,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const Text(
        'No attendance records for this booking yet.',
        style: TextStyle(
          fontSize: 13,
          color: EColorConstants.authPlaceholderGray,
          fontFamily: 'Poppins',
        ),
      );
    }

    final grouped = <String, List<DayAttendance>>{};
    for (final day in days) {
      final monday = _mondayOfWeek(day.sessionDate);
      final key = '${monday.year}-${monday.month}-${monday.day}';
      grouped.putIfAbsent(key, () => []).add(day);
    }

    final weekKeys = grouped.keys.toList()
      ..sort((a, b) {
        final aParts = a.split('-').map(int.parse).toList();
        final bParts = b.split('-').map(int.parse).toList();
        final aDate = DateTime(aParts[0], aParts[1], aParts[2]);
        final bDate = DateTime(bParts[0], bParts[1], bParts[2]);
        return aDate.compareTo(bDate);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Weekly Attendance',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: EColorConstants.authTextDarkBrown,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 12),
        ...weekKeys.map((key) {
          final weekDays = grouped[key]!..sort(
                (a, b) => a.sessionDate.compareTo(b.sessionDate),
              );
          final monday = _mondayOfWeek(weekDays.first.sessionDate);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Week of ${monday.day}/${monday.month}/${monday.year}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: EColorConstants.authPlaceholderGray,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: weekDays.map(_DayAttendanceChip.new).toList(),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        Row(
          children: const [
            _LegendDot(
              color: EColorConstants.primaryColor,
              label: 'Attended',
            ),
            SizedBox(width: 12),
            _LegendDot(
              color: Color(0xFFD32F2F),
              label: 'Missed',
            ),
            SizedBox(width: 12),
            _LegendDot(
              color: EColorConstants.authFieldBorder,
              label: 'Upcoming',
            ),
          ],
        ),
      ],
    );
  }

  DateTime _mondayOfWeek(DateTime date) {
    return DateTime(date.year, date.month, date.day - (date.weekday - 1));
  }
}

class _DayAttendanceChip extends StatelessWidget {
  final DayAttendance day;

  const _DayAttendanceChip(this.day);

  @override
  Widget build(BuildContext context) {
    final color = switch (day.status.toLowerCase()) {
      'attended' => EColorConstants.primaryColor,
      'missed' => const Color(0xFFD32F2F),
      'today' => const Color(0xFF2E7D32),
      _ => EColorConstants.authFieldBorder,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: day.isToday ? color : color.withOpacity(0.4),
          width: day.isToday ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            day.dayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${day.sessionDate.day}/${day.sessionDate.month}',
            style: const TextStyle(
              fontSize: 10,
              color: EColorConstants.authPlaceholderGray,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: EColorConstants.authPlaceholderGray,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}
