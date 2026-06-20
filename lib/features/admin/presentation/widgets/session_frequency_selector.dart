import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';

class SessionsPerWeekDropdown extends StatelessWidget {
  final int selectedCount;
  final bool enabled;
  final ValueChanged<int> onChanged;
  final String? errorText;

  const SessionsPerWeekDropdown({
    super.key,
    required this.selectedCount,
    this.enabled = true,
    required this.onChanged,
    this.errorText,
  });

  static const _options = [1, 2, 3, 4, 5, 6];

  static String labelFor(int count) => '${count}x per week';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sessions Per Week',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: EColorConstants.authTextDarkBrown,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          value: selectedCount,
          isExpanded: true,
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Iconsax.calendar,
              size: 18,
              color: EColorConstants.primaryColor,
            ),
            filled: true,
            fillColor: EColorConstants.authFieldBackground,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: EColorConstants.primaryColor.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: EColorConstants.primaryColor.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: EColorConstants.primaryColor,
                width: 1.2,
              ),
            ),
            errorText: errorText,
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
          items: _options
              .map(
                (count) => DropdownMenuItem(
                  value: count,
                  child: Text(
                    labelFor(count),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: EColorConstants.authTextDarkBrown,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: enabled
              ? (value) {
                  if (value != null) onChanged(value);
                }
              : null,
        ),
      ],
    );
  }
}
