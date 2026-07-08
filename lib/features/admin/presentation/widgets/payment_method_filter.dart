import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';

class PaymentMethodFilter extends StatelessWidget {
  const PaymentMethodFilter({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  static const options = [
    ('all', 'All'),
    ('cash', 'Cash'),
    ('instapay', 'InstaPay'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (value, label) = options[index];
          final isSelected = selected == value;

          return FilterChip(
            label: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isSelected
                    ? Colors.white
                    : EColorConstants.authTextDarkBrown,
              ),
            ),
            selected: isSelected,
            onSelected: (_) => onChanged(value),
            showCheckmark: false,
            selectedColor: EColorConstants.primaryColor,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected
                  ? EColorConstants.primaryColor
                  : EColorConstants.authFieldBorder,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          );
        },
      ),
    );
  }
}
