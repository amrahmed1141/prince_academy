import 'package:flutter/material.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_form_styles.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_searchable_dropdown_field.dart';

class AdminDropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T item) itemLabel;
  final IconData prefixIcon;
  final bool enabled;
  final ValueChanged<T?> onChanged;
  final String? errorText;
  final bool searchable;

  const AdminDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.prefixIcon,
    this.enabled = true,
    required this.onChanged,
    this.errorText,
    this.searchable = false,
  });

  @override
  Widget build(BuildContext context) {
    if (searchable) {
      return AdminSearchableDropdownField<T>(
        label: label,
        value: value,
        items: items,
        itemLabel: itemLabel,
        prefixIcon: prefixIcon,
        errorText: errorText,
        enabled: enabled,
        hintText: 'Select option',
        onChanged: onChanged,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminFormStyles.fieldLabel(label),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          decoration: AdminFormStyles.fieldDecoration(
            prefixIcon: prefixIcon,
            errorText: errorText,
          ),
          hint: const Text(
            'Select option',
            style: TextStyle(
              color: Color(0xFF8E8E93),
              fontFamily: 'Poppins',
              fontSize: 13,
            ),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    itemLabel(item),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }
}
