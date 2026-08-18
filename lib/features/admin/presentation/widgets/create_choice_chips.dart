import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/data/models/session_draft.dart';
import 'package:prince_academy/features/admin/presentation/widgets/specialty_chip.dart';

/// Single-select wrap of compact chips (specialty, class type).
class CreateChoiceChipWrap<T> extends StatelessWidget {
  const CreateChoiceChipWrap({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
    required this.labelOf,
  });

  final List<T> items;
  final T selected;
  final ValueChanged<T> onSelected;
  final String Function(T item) labelOf;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          _CreateChip(
            label: labelOf(item),
            selected: item == selected,
            onTap: () => onSelected(item),
          ),
      ],
    );
  }
}

/// One-row weekday toggles. Selected days drive sessions-per-week.
class WeekDayChipRow extends StatelessWidget {
  const WeekDayChipRow({
    super.key,
    required this.selectedDays,
    required this.onToggle,
    this.enabled = true,
  });

  final Set<String> selectedDays;
  final ValueChanged<String> onToggle;
  final bool enabled;

  static const shortLabels = {
    'Monday': 'Mon',
    'Tuesday': 'Tue',
    'Wednesday': 'Wed',
    'Thursday': 'Thu',
    'Friday': 'Fri',
    'Saturday': 'Sat',
    'Sunday': 'Sun',
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < SessionDraft.weekDays.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: _CreateChip(
              label: shortLabels[SessionDraft.weekDays[i]] ??
                  SessionDraft.weekDays[i],
              selected: selectedDays.contains(SessionDraft.weekDays[i]),
              enabled: enabled,
              compact: true,
              onTap: () => onToggle(SessionDraft.weekDays[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _CreateChip extends StatelessWidget {
  const _CreateChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? Colors.white
        : EColorConstants.authTextDarkBrown;
    final bg = selected
        ? EColorConstants.primaryColor
        : Colors.white;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: BoxConstraints(minHeight: compact ? 44 : 40),
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 2 : 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? EColorConstants.primaryColor
                  : const Color(0xFFE8DDD0),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: enabled ? fg : EColorConstants.authPlaceholderGray,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }
}

String specialtyChipLabel(String specialty) =>
    SpecialtyChip.displayLabel(specialty);
