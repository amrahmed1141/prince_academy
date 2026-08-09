import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/app_colors.dart';
import 'package:prince_academy/core/constants/colors.dart';

enum FinancePeriod { week, month, year }

class FinancePeriodSelector extends StatelessWidget {
  const FinancePeriodSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.onPrevious,
    this.onNext,
  });

  final FinancePeriod value;
  final ValueChanged<FinancePeriod> onChanged;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF0EBE4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: FinancePeriod.values.map((period) {
                final selected = period == value;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onChanged(period),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? EColorConstants.primaryColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _label(period),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
          ),
        ),
        if (onPrevious != null || onNext != null) ...[
          const SizedBox(width: 8),
          _NavIcon(
            icon: Icons.chevron_left_rounded,
            onTap: onPrevious,
          ),
          _NavIcon(
            icon: Icons.chevron_right_rounded,
            onTap: onNext,
          ),
        ],
      ],
    );
  }

  static String _label(FinancePeriod period) {
    return switch (period) {
      FinancePeriod.week => 'Week',
      FinancePeriod.month => 'Month',
      FinancePeriod.year => 'Year',
    };
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 22, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
