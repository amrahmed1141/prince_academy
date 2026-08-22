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
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (value, label) = options[index];
          final isSelected = selected == value;

          return Material(
            color: isSelected
                ? EColorConstants.primaryColor
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () => onChanged(value),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? EColorConstants.primaryColor
                        : EColorConstants.authFieldBorder,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isSelected
                        ? Colors.white
                        : EColorConstants.authTextDarkBrown,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
