import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prince_academy/core/constants/app_colors.dart';
import 'package:prince_academy/features/home/presentation/bloc/home_bloc.dart';
import 'package:prince_academy/features/sessions/data/models/session_model.dart';

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

    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        primary: false,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = HomeBloc.isSameDay(day, selectedDate);
          final dayName = DateFormat('E').format(day);
          final dayNumber = day.day.toString();
          final hasSession = _hasSessionOnDay(day);

          return GestureDetector(
            onTap: () => onDateSelected(HomeBloc.dateOnly(day)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isSelected ? const Color(0xFFE6E8EB) : Colors.transparent,
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
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color.fromARGB(255, 187, 187, 187),
                      ),
                      borderRadius: BorderRadius.circular(17),
                    ),
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
        },
      ),
    );
  }
}
