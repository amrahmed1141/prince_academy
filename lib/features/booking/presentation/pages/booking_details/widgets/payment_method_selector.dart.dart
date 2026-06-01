import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';

enum PaymentMethod { card, paypal, googlePay }

extension PaymentMethodX on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.card => 'Card (Visa/Mastercard)',
        PaymentMethod.paypal => 'PayPal',
        PaymentMethod.googlePay => 'Google Pay',
      };

  IconData get icon => switch (this) {
        PaymentMethod.card => Iconsax.card,
        PaymentMethod.paypal => Iconsax.money,
        PaymentMethod.googlePay => Iconsax.wallet,
      };
}

class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    final methods = PaymentMethod.values;

    return Column(
      children: methods.map((m) {
        final isSelected = selected == m;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onChanged(m),
            child: Ink(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? EColorConstants.primaryColor
                      : Colors.grey.shade200,
                  width: isSelected ? 1.6 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    m.icon,
                    color: isSelected
                        ? EColorConstants.primaryColor
                        : Colors.grey.shade700,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      m.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected
                                ? EColorConstants.primaryColor
                                : Colors.grey.shade800,
                          ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle,
                        color: EColorConstants.primaryColor),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}