import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/helpers/subscription_formatters.dart';
import 'package:prince_academy/features/admin/data/models/pending_payment_model.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';

class PendingPaymentCard extends StatelessWidget {
  const PendingPaymentCard({
    super.key,
    required this.payment,
    this.isVerifying = false,
    this.isRejecting = false,
    this.onVerify,
    this.onReject,
    this.onViewScreenshot,
  });

  final PendingPaymentModel payment;
  final bool isVerifying;
  final bool isRejecting;
  final VoidCallback? onVerify;
  final VoidCallback? onReject;
  final VoidCallback? onViewScreenshot;

  @override
  Widget build(BuildContext context) {
    final schedule = SubscriptionFormatters.formatDays(payment.selectedDays);
    final methodLabel = payment.isCash ? 'Cash' : 'InstaPay';
    final bookedAgo = SubscriptionFormatters.formatTimeAgo(payment.createdAt);
    final deadline = payment.paymentDeadline != null
        ? DateFormat('MMM d, yyyy').format(payment.paymentDeadline!.toLocal())
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF9A825).withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('👤', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  payment.userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    color: EColorConstants.authTextDarkBrown,
                  ),
                ),
              ),
              if (payment.userPhone != null && payment.userPhone!.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Iconsax.call,
                      size: 14,
                      color: EColorConstants.authPlaceholderGray,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      payment.userPhone!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: EColorConstants.authPlaceholderGray,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CoachAvatar(
                coachName: payment.coachName,
                photoUrl: payment.coachPhoto,
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoLine(
                      icon: Iconsax.user_octagon,
                      text:
                          'Coach: ${payment.coachName}${payment.coachSpecialty != null ? ' · ${payment.coachSpecialty}' : ''}',
                    ),
                    if (payment.branchName.isNotEmpty)
                      _InfoLine(
                        icon: Iconsax.location,
                        text: 'Branch: ${payment.branchName}',
                      ),
                    _InfoLine(
                      icon: Iconsax.calendar,
                      text: 'Days: $schedule · ${payment.selectedTime}',
                    ),
                    _InfoLine(
                      icon: Iconsax.wallet_3,
                      text:
                          'Amount: ${payment.totalPrice.toStringAsFixed(0)} EGP',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          const Text(
            'Payment Details',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: EColorConstants.authPlaceholderGray,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          _InfoLine(
            icon: payment.isCash ? Iconsax.money : Iconsax.mobile,
            text: 'Method: $methodLabel',
          ),
          _InfoLine(
            icon: Iconsax.clock,
            text: 'Booked: $bookedAgo',
          ),
          if (deadline != null)
            _InfoLine(
              icon: Iconsax.timer_1,
              text: 'Deadline: $deadline',
              color: const Color(0xFFF9A825),
            ),
          if (payment.isInstaPay && payment.paymentReference != null) ...[
            _InfoLine(
              icon: Iconsax.key,
              text: 'Reference: ${payment.paymentReference}',
            ),
            if (payment.paymentScreenshotUrl != null &&
                payment.paymentScreenshotUrl!.isNotEmpty) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onViewScreenshot,
                icon: const Icon(Iconsax.gallery, size: 18),
                label: const Text('View Screenshot'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: EColorConstants.primaryColor,
                  side: const BorderSide(color: EColorConstants.authFieldBorder),
                ),
              ),
            ],
          ],
          const SizedBox(height: 14),
          if (payment.isCash)
            _ActionButton(
              label: 'Confirm Payment Received',
              icon: Icons.check_circle_outline,
              color: const Color(0xFF2E7D32),
              isLoading: isVerifying,
              onPressed: onVerify,
            )
          else
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Verify Payment',
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF2E7D32),
                    isLoading: isVerifying,
                    onPressed: onVerify,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: 'Reject',
                    icon: Icons.close,
                    color: const Color(0xFFD32F2F),
                    isLoading: isRejecting,
                    onPressed: onReject,
                    outlined: true,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.text,
    this.color,
  });

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 14,
            color: color ?? EColorConstants.authPlaceholderGray,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color ?? EColorConstants.authTextDarkBrown,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.isLoading = false,
    this.outlined = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: outlined ? color : Colors.white,
            ),
          )
        : Icon(icon, size: 18);

    if (outlined) {
      return OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: child,
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.6)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: child,
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}
