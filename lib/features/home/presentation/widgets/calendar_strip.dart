import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prince_academy/core/constants/app_colors.dart';
import 'package:prince_academy/core/theme/app_gradients.dart';
import 'package:prince_academy/features/home/presentation/bloc/home_bloc.dart';
import 'package:prince_academy/features/sessions/data/models/session_model.dart';
import 'package:prince_academy/features/sessions/domain/weekly_progress_calculator.dart';
import 'package:prince_academy/features/sessions/domain/weekly_progress_summary.dart';

class CalendarStrip extends StatelessWidget {
  final DateTime selectedDate;
  final List<Session> allSessions;
  final ValueChanged<DateTime> onDateSelected;

  const CalendarStrip({
    super.key,
    required this.selectedDate,
    required this.allSessions,
    required this.onDateSelected,
  });

  List<DateTime> _weekDays() {
    final weekStart = _startOfWeek(selectedDate);
    return List.generate(
      7,
      (index) => weekStart.add(Duration(days: index)),
    );
  }

  DateTime _startOfWeek(DateTime date) {
    final d = HomeBloc.dateOnly(date);
    return d.subtract(Duration(days: d.weekday - DateTime.monday));
  }

  bool _hasSessionOnDay(DateTime day) {
    final isToday = HomeBloc.isSameDay(day, HomeBloc.today());
    return allSessions.any((s) {
      if (HomeBloc.isSameDay(s.sessionDate, day)) return true;
      if (isToday && s.isToday) return true;
      return false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = _weekDays();
    final today = HomeBloc.today();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 82,
        child: Row(
          children: [
            for (var index = 0; index < days.length; index++) ...[
              if (index > 0) const SizedBox(width: 8),
              Expanded(
                child: _CalendarDayCell(
                  day: days[index],
                  selectedDate: selectedDate,
                  hasSession: _hasSessionOnDay(days[index]),
                  attendance: WeeklyProgressCalculator.daySessionAttendance(
                    day: days[index],
                    sessions: allSessions,
                    today: today,
                  ),
                  onTap: () => onDateSelected(HomeBloc.dateOnly(days[index])),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.selectedDate,
    required this.hasSession,
    required this.attendance,
    required this.onTap,
  });

  final DateTime day;
  final DateTime selectedDate;
  final bool hasSession;
  final DaySessionAttendance? attendance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = HomeBloc.isSameDay(day, selectedDate);
    final dayName = DateFormat('E').format(day);
    final dayNumber = day.day.toString();

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFE6E8EB) : Colors.transparent,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              dayName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? AppColors.textPrimary
                    : const Color(0xFF9AA0A6),
              ),
            ),
            const SizedBox(height: 7),
            _DayAttendanceCircle(
              dayNumber: dayNumber,
              attendance: attendance,
            ),
            const SizedBox(height: 5),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isSelected || hasSession ? 1 : 0,
              child: Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected || hasSession
                      ? AppColors.primary
                      : Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Day number with a thin circular progress ring (stroke only — no fill).
class _DayAttendanceCircle extends StatelessWidget {
  static const double _size = 34;

  final String dayNumber;
  final DaySessionAttendance? attendance;

  const _DayAttendanceCircle({
    required this.dayNumber,
    required this.attendance,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: CustomPaint(
        painter: _DayAttendanceRingPainter(attendance: attendance),
        child: Center(
          child: Text(
            dayNumber,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _DayAttendanceRingPainter extends CustomPainter {
  static const double _strokeWidth = 1.5;
  static const Color _neutralRing = Color.fromARGB(255, 187, 187, 187);

  final DaySessionAttendance? attendance;

  const _DayAttendanceRingPainter({required this.attendance});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - _strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    final attendance = this.attendance;
    if (attendance == null) {
      track.color = _neutralRing;
      canvas.drawCircle(center, radius, track);
      return;
    }

    if (attendance.noneAttended) {
      track.color = AppColors.error;
      canvas.drawCircle(center, radius, track);
      return;
    }

    if (attendance.allAttended) {
      track.shader = AppGradients.sessionProgress.createShader(rect);
      canvas.drawCircle(center, radius, track);
      return;
    }

    // Partial: gradient arc for attended, red for the rest.
    final ratio = attendance.ratio;
    final attendedSweep = 2 * math.pi * ratio;
    const start = -math.pi / 2;

    final attendedPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = AppGradients.sessionProgress.createShader(rect);

    canvas.drawArc(rect, start, attendedSweep, false, attendedPaint);

    final missedPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = AppColors.error;

    canvas.drawArc(
      rect,
      start + attendedSweep,
      2 * math.pi - attendedSweep,
      false,
      missedPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DayAttendanceRingPainter oldDelegate) {
    return oldDelegate.attendance != attendance;
  }
}
