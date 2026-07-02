import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prince_academy/core/constants/app_colors.dart';
import 'package:prince_academy/features/home/presentation/bloc/home_bloc.dart';
import 'package:prince_academy/features/sessions/data/models/session_model.dart';

class DateStrip extends StatelessWidget {
  final DateTime selectedDate;
  final List<Session> allSessions;
  final ValueChanged<DateTime> onDateSelected;

  const DateStrip({
    super.key,
    required this.selectedDate,
    required this.allSessions,
    required this.onDateSelected,
  });

  List<DateTime> _daysFromToday() {
    final today = HomeBloc.dateOnly(DateTime.now());
    return List.generate(7, (i) => today.add(Duration(days: i)));
  }

  bool _hasSession(DateTime day) {
    return allSessions.any((s) => HomeBloc.isSameDay(s.sessionDate, day));
  }

  @override
  Widget build(BuildContext context) {
    final days = _daysFromToday();
    final today = HomeBloc.dateOnly(DateTime.now());

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        primary: false,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        clipBehavior: Clip.none,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = HomeBloc.isSameDay(day, selectedDate);
          final isToday = HomeBloc.isSameDay(day, today);
          final hasSession = _hasSession(day);
          final label = '${DateFormat('EEE').format(day)} ${day.day}';
          final highlighted = isToday || isSelected;

          return GestureDetector(
            onTap: () => onDateSelected(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 64,
              decoration: BoxDecoration(
                color: isToday
                    ? AppColors.primary
                    : isSelected
                        ? AppColors.primary.withOpacity(0.08)
                        : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: highlighted
                      ? AppColors.primary
                      : Colors.grey.shade300,
                  width: isSelected && !isToday ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isToday
                          ? Colors.white
                          : isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasSession
                          ? (isToday
                              ? Colors.white
                              : AppColors.primary)
                          : Colors.transparent,
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
