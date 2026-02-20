// view/mma_booking/widgets/booking_summary.dart
import 'package:flutter/material.dart';
import 'package:prince_academy/utils/constants/colors.dart';

class BookingSummary extends StatelessWidget {
  final int sessions;
  final String day;
  final String time;
  final double pricePerSession;

  const BookingSummary({
    super.key,
    required this.sessions,
    required this.day,
    required this.time,
    required this.pricePerSession,
  });

  @override
  Widget build(BuildContext context) {
    final totalPrice = sessions * pricePerSession;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Sessions', '$sessions sessions'),
            const SizedBox(height: 8),
            _buildSummaryRow('Day', day),
            const SizedBox(height: 8),
            _buildSummaryRow('Time', time),
            const SizedBox(height: 8),
            _buildSummaryRow('Price per session', '\$$pricePerSession'),
            const Divider(height: 24),
            _buildSummaryRow(
              'Total Amount',
              '\$${totalPrice.toStringAsFixed(2)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? EColorConstants.primaryColor : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
            color: isTotal ? EColorConstants.primaryColor : Colors.black,
          ),
        ),
      ],
    );
  }
}