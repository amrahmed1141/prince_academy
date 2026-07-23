import 'package:flutter/material.dart';
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

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
          SizedBox(width: 8),
          Text(
            'Booking Created!',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subscription: $period',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Pay $amount EGP at the academy within 3 days',
            style: TextStyle(
              color: Colors.grey.shade800,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Deadline: $deadlineText',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onClose();
          },
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onViewBookings();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: EColorConstants.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('View My Bookings'),
        ),
      ],
    );
  }
}
