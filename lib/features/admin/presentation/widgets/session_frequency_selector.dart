import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';

class SessionFrequencySelector extends StatelessWidget {
  final int selectedCount;
  final int maxCount;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const SessionFrequencySelector({
    super.key,
    required this.selectedCount,
    this.maxCount = 6,
    this.enabled = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(maxCount, (index) {
        final count = index + 1;
        final isSelected = selectedCount == count;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < maxCount - 1 ? 6 : 0),
            child: GestureDetector(
              onTap: enabled ? () => onChanged(count) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: isSelected
                      ? EColorConstants.primaryColor
                      : EColorConstants.authCardWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? EColorConstants.primaryColor
                        : EColorConstants.authFieldBorder,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${count}x',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : EColorConstants.authTextDarkBrown,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
