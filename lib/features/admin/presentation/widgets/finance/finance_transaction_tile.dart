import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prince_academy/core/constants/app_colors.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/data/repositories/finance_repository.dart';
import 'package:prince_academy/features/admin/presentation/widgets/finance/finance_currency.dart';

enum FinanceTxFilter { all, confirmed, pending }

class FinanceTxFilterChips extends StatelessWidget {
  const FinanceTxFilterChips({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final FinanceTxFilter value;
  final ValueChanged<FinanceTxFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: FinanceTxFilter.values.map((filter) {
        final selected = filter == value;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onChanged(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? EColorConstants.primaryColor
                    : const Color(0xFFF0EBE4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _label(filter),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }

  static String _label(FinanceTxFilter filter) {
    return switch (filter) {
      FinanceTxFilter.all => 'All',
      FinanceTxFilter.confirmed => 'Confirmed',
      FinanceTxFilter.pending => 'Pending',
    };
  }
}

class FinanceTransactionTile extends StatelessWidget {
  const FinanceTransactionTile({
    super.key,
    required this.transaction,
    required this.expanded,
    required this.onTap,
    this.isBusy = false,
    this.onConfirm,
    this.onCancel,
  });

  final FinanceTransaction transaction;
  final bool expanded;
  final VoidCallback onTap;
  final bool isBusy;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final isPending = transaction.isPending;
    final statusColor =
        isPending ? AppColors.pendingOrange : AppColors.success;
    final statusBg = isPending
        ? const Color(0xFFFFF3E0)
        : const Color(0xFFE8F5E9);
    final time = DateFormat('h:mm a').format(transaction.date.toLocal());
    final detail = [
      transaction.paymentMethodLabel,
      if (transaction.detail.isNotEmpty) transaction.detail,
      time,
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isPending ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: statusBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPending
                            ? Icons.schedule_rounded
                            : Icons.check_rounded,
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.memberName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            detail,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          FinanceCurrency.egp(transaction.amount),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isPending ? 'Pending' : 'Confirmed',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (isPending && expanded) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: ElevatedButton(
                            onPressed: isBusy ? null : onConfirm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: EColorConstants.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isBusy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Confirm',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: OutlinedButton(
                            onPressed: isBusy ? null : onCancel,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
