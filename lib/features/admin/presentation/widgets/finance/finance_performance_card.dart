import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prince_academy/core/constants/app_colors.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/data/repositories/finance_repository.dart';
import 'package:prince_academy/features/admin/presentation/widgets/finance/finance_currency.dart';

class FinancePerformanceCard extends StatelessWidget {
  const FinancePerformanceCard({
    super.key,
    required this.title,
    required this.total,
    required this.items,
    required this.selectedDay,
    required this.onDaySelected,
    this.labelBuilder,
  });

  final String title;
  final double total;
  final List<FinanceDailyIncome> items;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onDaySelected;
  final String Function(FinanceDailyIncome item, int index)? labelBuilder;

  @override
  Widget build(BuildContext context) {
    final maxValue = items.fold<double>(
      0,
      (max, item) => item.amount > max ? item.amount : max,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total: ${FinanceCurrency.egpPrefix(total)}',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var index = 0; index < items.length; index++)
                  _BarColumn(
                    item: items[index],
                    maxValue: maxValue,
                    selected: selectedDay != null &&
                        DateUtils.isSameDay(selectedDay, items[index].day),
                    label: labelBuilder?.call(items[index], index) ??
                        DateFormat('EEE')
                            .format(items[index].day)
                            .toUpperCase()
                            .substring(0, 3),
                    onTap: () => onDaySelected(items[index].day),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarColumn extends StatelessWidget {
  const _BarColumn({
    required this.item,
    required this.maxValue,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final FinanceDailyIncome item;
  final double maxValue;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue <= 0
        ? 0.08
        : (item.amount / maxValue).clamp(0.08, 1.0);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                height: 28,
                child: selected && item.amount > 0
                    ? Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.textPrimary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            FinanceCurrency.short(item.amount),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                height: 28 + (ratio * 52),
                decoration: BoxDecoration(
                  color: selected
                      ? EColorConstants.primaryColor
                      : const Color(0xFFE8DFD4),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? EColorConstants.primaryColor
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
