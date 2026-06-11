import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';

const kClassTypeFilterOptions = <String>[
  'All Classes',
  'BJJ',
  'Muay Thai',
  'Striking',
  'Grappling',
  'Boxing',
  'MMA',
];

class ClassTypeFilterDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const ClassTypeFilterDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = kClassTypeFilterOptions.contains(value)
        ? value
        : kClassTypeFilterOptions.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: EColorConstants.authCardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EColorConstants.authFieldBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isDense: true,
          isExpanded: true,
          value: selected,
          icon: const Icon(
            Iconsax.arrow_down_1,
            size: 14,
            color: EColorConstants.authPlaceholderGray,
          ),
          items: kClassTypeFilterOptions.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(
                option,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: EColorConstants.authTextDarkBrown,
                  fontFamily: 'Poppins',
                ),
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) onChanged(newValue);
          },
        ),
      ),
    );
  }
}
