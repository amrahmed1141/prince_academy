import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prince_academy/core/constants/app_colors.dart';
import 'package:prince_academy/core/helpers/session_schedule_helper.dart';
import 'package:prince_academy/core/helpers/subscription_formatters.dart';
import 'package:shimmer/shimmer.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarSchedulePicker extends StatelessWidget {
  final List<String> availableDays;
  final String sessionTime;
  final DateTime? selectedStartDate;
  final List<DateTime> sessionDates;
  final bool isLoading;
  final ValueChanged<DateTime> onStartDateSelected;

  const CalendarSchedulePicker({
    super.key,
    required this.availableDays,
    required this.sessionTime,
    required this.selectedStartDate,
    required this.sessionDates,
    this.isLoading = false,
    required this.onStartDateSelected,
  });

  DateTime get _today => SessionScheduleHelper.dateOnly(DateTime.now());

  Set<DateTime> get _sessionDaySet => sessionDates
      .map(SessionScheduleHelper.dateOnly)
      .toSet();

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _CalendarShimmer();
    }

    final focusedDay = selectedStartDate ?? _today;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available days',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableDays.map((day) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Text(
                SubscriptionFormatters.formatDays([day]),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontFamily: 'Poppins',
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        const Text(
          'Pick subscription start date',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TableCalendar<void>(
            firstDay: _today,
            lastDay: _today.add(const Duration(days: 365)),
            focusedDay: focusedDay.isBefore(_today) ? _today : focusedDay,
            selectedDayPredicate: (day) =>
                selectedStartDate != null &&
                SessionScheduleHelper.dateOnly(day) ==
                    SessionScheduleHelper.dateOnly(selectedStartDate!),
            onDaySelected: (selected, focused) {
              if (selected.isBefore(_today)) return;
              onStartDateSelected(selected);
            },
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
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
              markerDecoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                shape: BoxShape.circle,
              ),
              markersMaxCount: 1,
              markerSize: 6,
              outsideDaysVisible: false,
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                final normalized = SessionScheduleHelper.dateOnly(day);
                if (!_sessionDaySet.contains(normalized)) {
                  return null;
                }
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
        ),
        if (selectedStartDate != null) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
            ),
            child: Text(
              SessionScheduleHelper.formatPeriodWithMonth(
                selectedStartDate!,
                SessionScheduleHelper.subscriptionEndDate(selectedStartDate!),
              ),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${sessionDates.length} sessions this month',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Session preview',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(sessionDates.length.clamp(0, 8), (index) {
            final date = sessionDates[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                SessionScheduleHelper.formatSessionPreview(
                  date,
                  sessionTime,
                  index,
                ),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade800,
                  fontFamily: 'Poppins',
                ),
              ),
            );
          }),
          if (sessionDates.length > 8)
            Text(
              '+ ${sessionDates.length - 8} more sessions',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontFamily: 'Poppins',
              ),
            ),
        ],
      ],
    );
  }
}

class _CalendarShimmer extends StatelessWidget {
  const _CalendarShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 14,
            width: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              4,
              (_) => Container(
                width: 48,
                height: 32,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 320,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }
}
