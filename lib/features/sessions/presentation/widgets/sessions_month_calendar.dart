import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/app_colors.dart';
import 'package:prince_academy/core/helpers/session_schedule_helper.dart';
import 'package:prince_academy/features/sessions/data/models/calendar_session_model.dart';
import 'package:prince_academy/features/sessions/presentation/bloc/sessions_bloc.dart';
import 'package:table_calendar/table_calendar.dart';

/// Month calendar with green dots on scheduled session days.
class SessionsMonthCalendar extends StatelessWidget {
  final DateTime focusedDay;
  final List<CalendarSessionModel> calendarSessions;
  final ValueChanged<DateTime>? onDaySelected;

  const SessionsMonthCalendar({
    super.key,
    required this.focusedDay,
    required this.calendarSessions,
    this.onDaySelected,
  });

  Set<DateTime> get _sessionDays => calendarSessions
      .map((s) => SessionScheduleHelper.dateOnly(s.sessionDate))
      .toSet();

  @override
  Widget build(BuildContext context) {
    final today = SessionScheduleHelper.dateOnly(DateTime.now());

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TableCalendar<void>(
        firstDay: today.subtract(const Duration(days: 30)),
        lastDay: today.add(const Duration(days: 365)),
        focusedDay: focusedDay,
        selectedDayPredicate: (day) =>
            SessionsBloc.isSameDay(day, focusedDay),
        onDaySelected: (selected, focused) => onDaySelected?.call(selected),
        calendarFormat: CalendarFormat.month,
        startingDayOfWeek: StartingDayOfWeek.sunday,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.w800,
            fontFamily: 'Poppins',
          ),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          todayTextStyle: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(color: Colors.white),
          outsideDaysVisible: false,
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            final normalized = SessionScheduleHelper.dateOnly(day);
            if (!_sessionDays.contains(normalized)) return null;
            return Positioned(
              bottom: 1,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
