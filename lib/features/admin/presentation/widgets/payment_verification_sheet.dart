import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:prince_academy/core/constants/app_colors.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/helpers/subscription_formatters.dart';
import 'package:prince_academy/features/admin/data/models/payment_verification_data.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';
import 'package:prince_academy/features/admin/presentation/widgets/payment_screenshot_viewer.dart';
import 'package:prince_academy/features/admin/presentation/widgets/reject_payment_dialog.dart';

class PaymentVerificationSheet extends StatelessWidget {
  const PaymentVerificationSheet({
    super.key,
    required this.data,
    required this.onVerify,
    this.onReject,
    this.isVerifying = false,
    this.isRejecting = false,
  });

  final PaymentVerificationData data;
  final Future<void> Function() onVerify;
  final Future<void> Function(String reason)? onReject;
  final bool isVerifying;
  final bool isRejecting;

  static Future<void> show(
    BuildContext context, {
    required PaymentVerificationData data,
    required Future<void> Function() onVerify,
    Future<void> Function(String reason)? onReject,
    bool isVerifying = false,
    bool isRejecting = false,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PaymentVerificationSheet(
        data: data,
        onVerify: onVerify,
        onReject: onReject,
        isVerifying: isVerifying,
        isRejecting: isRejecting,
      ),
    );
  }

  Future<void> _handleReject(BuildContext context) async {
    if (onReject == null || isRejecting || isVerifying) return;
    final reason = await RejectPaymentDialog.show(context);
    if (reason == null || !context.mounted) return;
    await onReject!(reason);
  }

  void _viewScreenshot(BuildContext context) {
    final url = data.paymentScreenshotUrl;
    if (url == null || url.isEmpty) return;
    PaymentScreenshotViewer.show(context, url);
  }

  @override
  Widget build(BuildContext context) {
    final bookedAgo = data.createdAt != null
        ? SubscriptionFormatters.formatTimeAgo(data.createdAt!)
        : 'Recently';
    final deadline = data.paymentDeadline != null
        ? DateFormat('MMM d, yyyy').format(data.paymentDeadline!.toLocal())
        : null;
    final deleteDays = data.autoDeleteDaysRemaining;
    final methodLabel = data.isCash ? 'Cash' : 'InstaPay';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Header with gradient background
          Container(
            padding: const EdgeInsets.fromLTRB(24, 14, 20, 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.06),
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Verification',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Poppins',
                          color: EColorConstants.authTextDarkBrown,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Review and confirm the payment below',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Icon(Icons.close, size: 16, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 28,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Coach card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: CoachAvatar(
                                coachName: data.coachName,
                                photoUrl: data.coachPhoto,
                                size: 56,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.coachName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Poppins',
                                color: EColorConstants.authTextDarkBrown,
                              ),
                            ),
                            if (data.coachSpecialty != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                data.coachSpecialty!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Text(
                          '${data.totalPrice.toStringAsFixed(0)} EGP',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Details card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _DetailTile(
                        icon: data.isCash ? Iconsax.money : Iconsax.mobile,
                        title: 'Payment Method',
                        value: methodLabel,
                        isFirst: true,
                      ),
                      _DetailTile(
                        icon: Iconsax.clock,
                        title: 'Booked',
                        value: bookedAgo,
                      ),
                      if (deadline != null)
                        _DetailTile(
                          icon: Iconsax.timer_1,
                          title: 'Deadline',
                          value: deadline,
                          valueColor: AppColors.warning,
                        ),
                      if (data.isCash)
                        _DetailTile(
                          icon: Iconsax.warning_2,
                          title: 'Auto-delete',
                          value: 'In $deleteDays day${deleteDays == 1 ? '' : 's'}',
                          valueColor: AppColors.warning,
                          isLast: true,
                        ),
                      if (data.isInstaPay && data.paymentReference != null)
                        _DetailTile(
                          icon: Iconsax.key,
                          title: 'Reference',
                          value: data.paymentReference!,
                          isLast: true,
                        ),
                    ],
                  ),
                ),
                if (data.isInstaPay &&
                    data.paymentScreenshotUrl != null &&
                    data.paymentScreenshotUrl!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _viewScreenshot(context),
                    icon: const Icon(Iconsax.gallery, size: 18),
                    label: const Text('View Screenshot'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (data.isCash)
                  _ActionButton(
                    label: 'Confirm Payment Received',
                    color: AppColors.success,
                    isLoading: isVerifying,
                    onPressed: isVerifying || isRejecting ? null : onVerify,
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: 'Verify Payment',
                          color: AppColors.success,
                          isLoading: isVerifying,
                          onPressed: isVerifying || isRejecting ? null : onVerify,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionButton(
                          label: 'Reject',
                          color: AppColors.error,
                          outlined: true,
                          isLoading: isRejecting,
                          onPressed: isVerifying || isRejecting
                              ? null
                              : () => _handleReject(context),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
    this.isFirst = false,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: (valueColor ?? AppColors.primary).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: valueColor ?? EColorConstants.authPlaceholderGray,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? EColorConstants.authTextDarkBrown,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey.shade200,
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.isLoading = false,
    this.outlined = false,
  });

  final String label;
  final Color color;
  final Future<void> Function()? onPressed;
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
        : null;

    if (outlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : () => onPressed?.call(),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.6)),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: child ?? Text(label, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : () => onPressed?.call(),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        elevation: 0,
      ),
      child: child ?? Text(label, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
    );
  }
}
