import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/data/models/session_draft.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_form_styles.dart';

class SessionDetailsPanel extends StatelessWidget {
  final List<SessionSlot> slots;
  final List<String> weekDays;
  final List<String> classTypes;
  final bool enabled;
  final void Function(int index, SessionSlot slot) onSlotChanged;

  const SessionDetailsPanel({
    super.key,
    required this.slots,
    required this.weekDays,
    required this.classTypes,
    required this.enabled,
    required this.onSlotChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminFormStyles.sectionTitle('Session Details'),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: AdminFormStyles.sessionDetailsPanelDecoration,
          child: Column(
            children: List.generate(slots.length, (index) {
              return Column(
                children: [
                  if (index > 0) ...[
                    const SizedBox(height: 14),
                    Divider(height: 1, color: Colors.brown.shade100),
                    const SizedBox(height: 14),
                  ],
                  SessionDraftRow(
                    index: index,
                    slot: slots[index],
                    weekDays: weekDays,
                    classTypes: classTypes,
                    enabled: enabled,
                    onChanged: (slot) => onSlotChanged(index, slot),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE8DDD0)),
              ),
              child: Text(
                'Session ${index + 1}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: EColorConstants.authTextDarkBrown,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            const Spacer(),
            Icon(
              Icons.drag_indicator,
              size: 22,
              color: Colors.grey.shade400,
            ),
          ],
        ),
        const SizedBox(height: 14),
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
                  const SizedBox(height: 12),
                  typeField,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: dayField),
                const SizedBox(width: 12),
                Expanded(child: typeField),
              ],
            );
          },
        ),
      ],
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
        AdminFormStyles.fieldLabel(label),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: AdminFormStyles.fieldDecoration(prefixIcon: prefixIcon),
          selectedItemBuilder: (context) {
            return items.map((item) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
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
