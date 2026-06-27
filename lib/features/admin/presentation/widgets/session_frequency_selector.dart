import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_form_styles.dart';

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
        AdminFormStyles.fieldLabel('Sessions Per Week'),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: selectedCount,
          isExpanded: true,
          decoration: AdminFormStyles.fieldDecoration(
            prefixIcon: Iconsax.calendar,
            errorText: errorText,
          ),
          items: _options
              .map(
                (count) => DropdownMenuItem(
                  value: count,
                  child: Text(
                    labelFor(count),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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
