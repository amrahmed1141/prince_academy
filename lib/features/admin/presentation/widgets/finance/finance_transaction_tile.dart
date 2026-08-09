import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/app_colors.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/data/repositories/finance_repository.dart';
import 'package:prince_academy/features/admin/presentation/widgets/finance/finance_currency.dart';

enum FinanceTxFilter { all, confirmed, pending, autoCanceled }

class FinanceTxFilterChips extends StatelessWidget {
  const FinanceTxFilterChips({
    super.key,
    required this.value,
    required this.onChanged,
    this.showAll = true,
  });

  final FinanceTxFilter value;
  final ValueChanged<FinanceTxFilter> onChanged;
  final bool showAll;

  @override
  Widget build(BuildContext context) {
    final filters = showAll
        ? FinanceTxFilter.values
        : const [
            FinanceTxFilter.confirmed,
            FinanceTxFilter.pending,
            FinanceTxFilter.autoCanceled,
          ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final selected = filter == value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? EColorConstants.primaryColor
                      : const Color(0xFFF0EBE4),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: EColorConstants.primaryColor.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
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
      ),
    );
  }

  static String _label(FinanceTxFilter filter) {
    return switch (filter) {
      FinanceTxFilter.all => 'All',
      FinanceTxFilter.confirmed => 'Confirmed',
      FinanceTxFilter.pending => 'Pending',
      FinanceTxFilter.autoCanceled => 'Auto-canceled',
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
    final statusColor = switch (transaction.status) {
      FinancePaymentStatus.pending => AppColors.pendingOrange,
      FinancePaymentStatus.autoCanceled => AppColors.expiredGrey,
      FinancePaymentStatus.rejected => AppColors.error,
      FinancePaymentStatus.confirmed => AppColors.success,
    };
    final statusBg = switch (transaction.status) {
      FinancePaymentStatus.pending => const Color(0xFFFFF3E0),
      FinancePaymentStatus.autoCanceled => const Color(0xFFF5F5F5),
      FinancePaymentStatus.rejected => const Color(0xFFFFEBEE),
      FinancePaymentStatus.confirmed => const Color(0xFFE8F5E9),
    };
    final statusLabel = switch (transaction.status) {
      FinancePaymentStatus.pending => 'Pending',
      FinancePaymentStatus.autoCanceled => 'Auto-canceled',
      FinancePaymentStatus.rejected => 'Rejected',
      FinancePaymentStatus.confirmed => 'Confirmed',
    };
    final detail = [
      transaction.paymentMethodLabel,
      if (transaction.detail.isNotEmpty) transaction.detail,
    ].join(' · ');
    final dateTime = FinanceCurrency.formatDateTime(transaction.date);

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
          onTap: transaction.isPending ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        switch (transaction.status) {
                          FinancePaymentStatus.pending =>
                            Icons.schedule_rounded,
                          FinancePaymentStatus.autoCanceled =>
                            Icons.timer_off_outlined,
                          FinancePaymentStatus.rejected => Icons.close_rounded,
                          FinancePaymentStatus.confirmed => Icons.check_rounded,
                        },
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateTime,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (transaction.isAutoCanceled &&
                              (transaction.cancelReason?.isNotEmpty ??
                                  false)) ...[
                            const SizedBox(height: 4),
                            Text(
                              transaction.cancelReason!,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.expiredGrey,
                              ),
                            ),
                          ],
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
                            statusLabel,
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
                if (transaction.isPending && expanded) ...[
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
                          child: ElevatedButton(
                            onPressed: isBusy ? null : onCancel,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF0EBE4),
                              foregroundColor: AppColors.textPrimary,
                              elevation: 0,
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
