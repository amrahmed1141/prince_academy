import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';

class ScheduleSelector extends StatelessWidget {
  const ScheduleSelector({
    super.key,
    required this.availableDays,
    required this.availableTimes,
    required this.selectedDays,
    required this.selectedTime,
    required this.onToggleDay,
    required this.onSelectTime,
  });

  final List<String> availableDays;
  final List<String> availableTimes;
  final Set<String> selectedDays;
  final String? selectedTime;
  final void Function(String day) onToggleDay;
  final void Function(String time) onSelectTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Days',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: availableDays.map((day) {
              final isSelected = selectedDays.contains(day);
              return ChoiceChip(
                label: Text(day),
                selected: isSelected,
                onSelected: (_) => onToggleDay(day),
                selectedColor: EColorConstants.primaryColor.withOpacity(0.12),
                labelStyle: TextStyle(
                  color: isSelected
                      ? EColorConstants.primaryColor
                      : Colors.grey.shade700,
                  fontWeight: FontWeight.w700,
                ),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: isSelected
                        ? EColorConstants.primaryColor
                        : Colors.grey.shade300,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Time',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: availableTimes.map((t) {
              final isSelected = selectedTime == t;
              return FilterChip(
                label: Text(t),
                selected: isSelected,
                onSelected: (_) => onSelectTime(t),
                selectedColor: EColorConstants.primaryColor,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade800,
                  fontWeight: FontWeight.w700,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Text(
            'Later: we’ll validate availability with coach schedule.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ],
      ),
    );
  }
}