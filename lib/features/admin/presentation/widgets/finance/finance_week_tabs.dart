import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/app_colors.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/presentation/widgets/finance/finance_currency.dart';

class FinanceWeekTabData {
  const FinanceWeekTabData({
    required this.weekNumber,
    required this.amount,
  });

  final int weekNumber;
  final double amount;
}

class FinanceWeekTabs extends StatelessWidget {
  const FinanceWeekTabs({
    super.key,
    required this.weeks,
    required this.selectedWeek,
    required this.onSelected,
  });

  final List<FinanceWeekTabData> weeks;
  final int selectedWeek;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: weeks.map((week) {
        final selected = week.weekNumber == selectedWeek;
        return Expanded(
          child: InkWell(
            onTap: () => onSelected(week.weekNumber),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  Text(
                    'WEEK ${week.weekNumber}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? EColorConstants.primaryColor
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    FinanceCurrency.egp(week.amount, decimals: false),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 2.5,
                    width: selected ? 36 : 0,
                    decoration: BoxDecoration(
                      color: EColorConstants.primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}
