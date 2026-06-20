import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';

class MultiSelectChipRow extends StatelessWidget {
  final List<String> options;
  final List<String> selected;
  final ValueChanged<String> onToggle;
  final bool enabled;

  const MultiSelectChipRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          onSelected: enabled ? (_) => onToggle(option) : null,
          selectedColor: EColorConstants.primaryColor,
          checkmarkColor: Colors.white,
          backgroundColor: EColorConstants.authFieldBackground,
          side: BorderSide(
            color: isSelected
                ? EColorConstants.primaryColor
                : EColorConstants.authFieldBorder,
          ),
          labelStyle: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: isSelected ? Colors.white : EColorConstants.authTextDarkBrown,
          ),
        );
      }).toList(),
    );
  }
}
