import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/app_colors.dart';
import 'package:prince_academy/core/helpers/subscription_formatters.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';
import 'package:prince_academy/features/booking/data/models/booking_history_model.dart';
import 'package:prince_academy/features/booking/data/models/booking_model.dart';

class RenewBookingPromptCard extends StatelessWidget {
  const RenewBookingPromptCard({
    super.key,
    required this.booking,
    required this.onRenew,
    required this.onCancel,
    this.isBusy = false,
    this.remainingCount = 0,
  });

  final BookingHistoryModel booking;
  final VoidCallback onRenew;
  final VoidCallback onCancel;
  final bool isBusy;
  final int remainingCount;

  static Future<bool?> show(
    BuildContext context, {
    required BookingHistoryModel booking,
    required VoidCallback onRenew,
    required VoidCallback onCancel,
    bool isBusy = false,
    int remainingCount = 0,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: RenewBookingPromptCard(
          booking: booking,
          onRenew: onRenew,
          onCancel: onCancel,
          isBusy: isBusy,
          remainingCount: remainingCount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final method = _methodLabel(booking.paymentMethod);
    final schedule = [
      SubscriptionFormatters.formatDays(booking.selectedDays),
      if (booking.selectedTime != null && booking.selectedTime!.isNotEmpty)
        booking.selectedTime!,
    ].join(' · ');

    return Material(
      color: Colors.white,
      elevation: 18,
      shadowColor: Colors.black.withOpacity(0.18),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Renew your booking',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              booking.effectiveDisplayStatus == 'completed'
                  ? 'This plan is finished. Keep the same days and price.'
                  : 'This plan has expired. Keep the same days and price.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CoachAvatar(
                  coachName: booking.coachName,
                  photoUrl: booking.coachPhoto,
                  size: 56,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.coachName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (booking.coachSpecialty != null &&
                          booking.coachSpecialty!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          booking.coachSpecialty!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(label: 'Schedule', value: schedule),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Price',
              value: '${booking.totalPrice.toStringAsFixed(0)} EGP',
            ),
            const SizedBox(height: 8),
            _InfoRow(label: 'Last payment', value: method),
            if (remainingCount > 0) ...[
              const SizedBox(height: 12),
              Text(
                '+$remainingCount more to review',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isBusy ? null : onCancel,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: AppColors.textPrimary,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Cancel',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isBusy ? null : onRenew,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Renew',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _methodLabel(String? raw) {
    final value = raw?.toLowerCase().trim();
    if (value == PaymentMethod.instapay.name) return PaymentMethod.instapay.label;
    if (value == PaymentMethod.cash.name) return PaymentMethod.cash.label;
    return 'Not set';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
