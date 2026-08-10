import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prince_academy/core/constants/app_colors.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/data/repositories/finance_repository.dart';
import 'package:prince_academy/features/admin/presentation/widgets/finance/finance_currency.dart';

class FinanceWeekDayTotals extends StatelessWidget {
  const FinanceWeekDayTotals({
    super.key,
    required this.days,
    required this.selectedDay,
    required this.onDaySelected,
  });

  final List<FinanceDailyIncome> days;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var index = 0; index < days.length; index++)
            _DayRow(
              day: days[index],
              selected: selectedDay != null &&
                  DateUtils.isSameDay(selectedDay, days[index].day),
              showDivider: index < days.length - 1,
              onTap: () => onDaySelected(days[index].day),
            ),
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.selected,
    required this.showDivider,
    required this.onTap,
  });

  final FinanceDailyIncome day;
  final bool selected;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dayName = DateFormat('EEEE').format(day.day);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: day.day.weekday == DateTime.monday
              ? const Radius.circular(16)
              : Radius.zero,
          bottom: day.day.weekday == DateTime.sunday
              ? const Radius.circular(16)
              : Radius.zero,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      dayName,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
                        color: selected
                            ? EColorConstants.primaryColor
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    FinanceCurrency.egp(day.amount),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? EColorConstants.primaryColor
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (showDivider)
              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFF0EBE4),
                indent: 16,
                endIndent: 16,
              ),
          ],
        ),
      ),
    );
  }
}
