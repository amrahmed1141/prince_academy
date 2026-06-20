import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/data/models/session_draft.dart';

class SessionDraftRow extends StatelessWidget {
  final int index;
  final SessionSlot slot;
  final List<String> weekDays;
  final List<String> classTypes;
  final bool enabled;
  final ValueChanged<SessionSlot> onChanged;

  const SessionDraftRow({
    super.key,
    required this.index,
    required this.slot,
    required this.weekDays,
    required this.classTypes,
    this.enabled = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Session ${index + 1}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: EColorConstants.authTextDarkBrown,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final stackFields = constraints.maxWidth < 340;

              final dayField = _buildDropdown(
                label: 'Day',
                value: slot.day,
                prefixIcon: Iconsax.calendar_1,
                items: weekDays,
                onChanged: (value) {
                  if (value != null) {
                    onChanged(slot.copyWith(day: value));
                  }
                },
              );

              final typeField = _buildDropdown(
                label: 'Class Type',
                value: slot.classType,
                prefixIcon: Iconsax.category,
                items: classTypes,
                onChanged: (value) {
                  if (value != null) {
                    onChanged(slot.copyWith(classType: value));
                  }
                },
              );

              if (stackFields) {
                return Column(
                  children: [
                    dayField,
                    const SizedBox(height: 10),
                    typeField,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: dayField),
                  const SizedBox(width: 10),
                  Expanded(child: typeField),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required IconData prefixIcon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: EColorConstants.authPlaceholderGray,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            prefixIcon: Icon(
              prefixIcon,
              size: 18,
              color: EColorConstants.primaryColor,
            ),
            filled: true,
            fillColor: EColorConstants.authFieldBackground,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                width: 1.5,
              ),
            ),
          ),
          selectedItemBuilder: (context) {
            return items.map((item) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: EColorConstants.authTextDarkBrown,
                  ),
                ),
              );
            }).toList();
          },
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'Poppins'),
              ),
            );
          }).toList(),
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }
}
