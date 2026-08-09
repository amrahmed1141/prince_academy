import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/app_colors.dart';
import 'package:prince_academy/features/admin/presentation/widgets/finance/finance_currency.dart';

class FinanceCompactKpiRow extends StatelessWidget {
  const FinanceCompactKpiRow({
    super.key,
    required this.todayAmount,
    required this.weeklyAmount,
    required this.monthlyAmount,
    this.todayChange,
    this.weeklyChange,
    this.monthlyChange,
  });

  final double todayAmount;
  final double weeklyAmount;
  final double monthlyAmount;
  final double? todayChange;
  final double? weeklyChange;
  final double? monthlyChange;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FinanceCompactKpiCard(
            label: 'Today',
            amount: todayAmount,
            changePercent: todayChange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FinanceCompactKpiCard(
            label: 'Weekly',
            amount: weeklyAmount,
            changePercent: weeklyChange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FinanceCompactKpiCard(
            label: 'Monthly',
            amount: monthlyAmount,
            changePercent: monthlyChange,
          ),
        ),
      ],
    );
  }
}

class FinanceCompactKpiCard extends StatelessWidget {
  const FinanceCompactKpiCard({
    super.key,
    required this.label,
    required this.amount,
    this.changePercent,
  });

  final String label;
  final double amount;
  final double? changePercent;

  @override
  Widget build(BuildContext context) {
    final change = changePercent;
    final isUp = (change ?? 0) >= 0;
    final changeColor = isUp ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              letterSpacing: 0.4,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            FinanceCurrency.egp(amount, decimals: false),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (change != null) ...[
            const SizedBox(height: 6),
            Text(
              '${isUp ? '+' : ''}${change.toStringAsFixed(0)}%',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: changeColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class FinanceNavRow extends StatelessWidget {
  const FinanceNavRow({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
