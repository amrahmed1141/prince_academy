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
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isDense: true,
          isExpanded: true,
          value: selected,
          icon: Icon(
            Iconsax.arrow_down_1,
            size: 14,
            color: Colors.grey.shade600,
          ),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: EColorConstants.authTextDarkBrown,
            fontFamily: 'Poppins',
          ),
          items: kClassTypeFilterOptions.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(
                option,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
