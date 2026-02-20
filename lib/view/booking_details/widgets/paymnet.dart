// view/mma_booking/widgets/payment_section.dart
import 'package:flutter/material.dart';
import 'package:prince_academy/utils/constants/colors.dart';

class PaymentSection extends StatelessWidget {
  final double totalPrice;
  final VoidCallback onPaymentPressed;

  const PaymentSection({
    super.key,
    required this.totalPrice,
    required this.onPaymentPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Total Price
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total to Pay',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              '\$${totalPrice.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: EColorConstants.primaryColor,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Book Now Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPaymentPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: EColorConstants.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Book Now & Pay',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Secure Payment Note
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              'Secure payment processed securely',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}