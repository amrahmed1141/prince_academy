import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';

class ScheduleSelector extends StatelessWidget {
  const ScheduleSelector({
    super.key,
    required this.availableDays,
    required this.selectedDays,
    required this.fixedTime,
    required this.isLocked,
    required this.onToggleDay,
  });

  final List<String> availableDays;
  final List<String> selectedDays;
  final String fixedTime;
  final bool isLocked;
  final void Function(String day) onToggleDay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EColorConstants.authFieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select your training days',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: availableDays.map((day) {
              final isSelected = selectedDays.contains(day);
              return FilterChip(
                label: Text(day),
                selected: isSelected,
                showCheckmark: true,
                onSelected: isLocked ? null : (_) => onToggleDay(day),
                selectedColor: EColorConstants.primaryColor,
                checkmarkColor: Colors.white,
                backgroundColor: EColorConstants.authFieldBackground,
                side: BorderSide(
                  color: isSelected
                      ? EColorConstants.primaryColor
                      : EColorConstants.authFieldBorder,
                ),
                labelStyle: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : EColorConstants.authTextDarkBrown,
                  fontWeight: FontWeight.w700,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.access_time,
                  size: 18,
                  color: EColorConstants.primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Time',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: EColorConstants.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      fixedTime,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: EColorConstants.primaryColor,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
