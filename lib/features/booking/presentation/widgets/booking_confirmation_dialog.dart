import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/helpers/session_schedule_helper.dart';
import 'package:prince_academy/features/booking/data/models/booking_model.dart';

class BookingConfirmationDialog extends StatelessWidget {
  final BookingModel booking;
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback onClose;
  final VoidCallback onViewBookings;

  const BookingConfirmationDialog({
    super.key,
    required this.booking,
    required this.startDate,
    required this.endDate,
    required this.onClose,
    required this.onViewBookings,
  });

  static Future<void> show(
    BuildContext context, {
    required BookingModel booking,
    required DateTime startDate,
    required DateTime endDate,
    required VoidCallback onClose,
    required VoidCallback onViewBookings,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BookingConfirmationDialog(
        booking: booking,
        startDate: startDate,
        endDate: endDate,
        onClose: onClose,
        onViewBookings: onViewBookings,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final period = SessionScheduleHelper.formatPeriod(startDate, endDate);
    final amount = booking.totalPrice.toStringAsFixed(0);
    final deadline = booking.paymentDeadline ??
        DateTime.now().add(const Duration(days: 3));
    final deadlineText = DateFormat('MMMM d, yyyy').format(deadline);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        elevation: 16,
        shadowColor: Colors.black.withOpacity(0.18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Iconsax.tick_circle5,
                  color: Color(0xFF2E7D32),
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Booking Created!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Poppins',
                  color: EColorConstants.authTextDarkBrown,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                decoration: BoxDecoration(
                  color: EColorConstants.authFieldBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: EColorConstants.authFieldBorder.withOpacity(0.7),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailRow(
                      icon: Iconsax.calendar_1,
                      label: 'Subscription',
                      value: period,
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Iconsax.wallet_3,
                      label: 'Pay at academy',
                      value: '$amount EGP within 3 days',
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Iconsax.timer_1,
                      label: 'Deadline',
                      value: deadlineText,
                      valueColor: const Color(0xFFB7791F),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onClose();
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: EColorConstants.authTextDarkBrown,
                        side: const BorderSide(
                          color: EColorConstants.authFieldBorder,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onViewBookings();
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: EColorConstants.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'View My Bookings',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Poppins',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 16,
            color: EColorConstants.primaryColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: EColorConstants.authPlaceholderGray,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  color: valueColor ?? EColorConstants.authTextDarkBrown,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
