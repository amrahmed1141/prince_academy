import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/app_colors.dart';
import 'package:prince_academy/features/admin/presentation/widgets/finance/finance_currency.dart';

class FinanceRevenueCard extends StatelessWidget {
  const FinanceRevenueCard({
    super.key,
    required this.label,
    required this.amount,
    this.changePercent,
    this.changeSubtitle,
  });

  final String label;
  final double amount;
  final double? changePercent;
  final String? changeSubtitle;

  @override
  Widget build(BuildContext context) {
    final change = changePercent;
    final isUp = (change ?? 0) >= 0;
    final changeColor = isUp ? AppColors.success : AppColors.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            FinanceCurrency.egp(amount),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 28,
              height: 1.15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (change != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  size: 14,
                  color: changeColor,
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    '${isUp ? '+' : ''}${change.toStringAsFixed(0)}%'
                    '${changeSubtitle == null ? '' : ' $changeSubtitle'}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: changeColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
