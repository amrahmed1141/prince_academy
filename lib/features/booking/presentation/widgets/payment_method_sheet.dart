import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/booking/data/models/booking_model.dart';
import 'package:prince_academy/features/booking/presentation/pages/booking_details/widgets/payment_method_selector.dart';

class PaymentMethodSheet extends StatelessWidget {
  final PaymentMethod selected;
  final double totalPrice;
  final ValueChanged<PaymentMethod> onChanged;

  const PaymentMethodSheet({
    super.key,
    required this.selected,
    required this.totalPrice,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose how you want to pay ${totalPrice.toStringAsFixed(0)} EGP',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 14),
        PaymentMethodSelector(
          selected: selected,
          onChanged: onChanged,
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: EColorConstants.primaryColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            selected == PaymentMethod.cash
                ? 'Pay at the academy within 3 days after booking.'
                : 'Transfer via InstaPay, then upload your screenshot.',
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }
}
