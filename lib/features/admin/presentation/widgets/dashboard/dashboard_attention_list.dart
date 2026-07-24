import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/data/models/pending_payment_model.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_section_card.dart';

class DashboardAttentionList extends StatelessWidget {
  const DashboardAttentionList({
    super.key,
    required this.payments,
    this.onSeeAll,
    this.onPaymentTap,
  });

  final List<PendingPaymentModel> payments;
  final VoidCallback? onSeeAll;
  final ValueChanged<PendingPaymentModel>? onPaymentTap;

  static final _currency = NumberFormat.currency(
    locale: 'en',
    symbol: 'EGP ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Needs attention',
                style: TextStyle(
                  color: EColorConstants.authTextDarkBrown,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            if (payments.isNotEmpty)
              TextButton(
                onPressed: onSeeAll,
                style: TextButton.styleFrom(
                  foregroundColor: EColorConstants.primaryColor,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'See all',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (payments.isEmpty)
          AdminSectionCard(
            borderRadius: 18,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            child: Column(
              children: [
                Icon(
                  Iconsax.tick_circle,
                  size: 36,
                  color: EColorConstants.primaryColor.withOpacity(0.7),
                ),
                const SizedBox(height: 10),
                const Text(
                  'All clear',
                  style: TextStyle(
                    color: EColorConstants.authTextDarkBrown,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'No payments waiting for verification.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: EColorConstants.authPlaceholderGray,
                    fontSize: 13,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          )
        else
          AdminSectionCard(
            borderRadius: 18,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < payments.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: EColorConstants.authFieldBorder,
                    ),
                  _AttentionRow(
                    payment: payments[i],
                    amountLabel: _currency.format(payments[i].totalPrice),
                    onTap: () => onPaymentTap?.call(payments[i]),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({
    required this.payment,
    required this.amountLabel,
    this.onTap,
  });

  final PendingPaymentModel payment;
  final String amountLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final method = payment.isCash ? 'Cash' : 'InstaPay';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE65100).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Iconsax.wallet_money,
                  size: 18,
                  color: Color(0xFFE65100),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: EColorConstants.authTextDarkBrown,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$method · ${payment.coachName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: EColorConstants.authPlaceholderGray,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                amountLabel,
                style: const TextStyle(
                  color: EColorConstants.authTextDarkBrown,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Iconsax.arrow_right_3,
                size: 16,
                color: EColorConstants.authPlaceholderGray,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
