import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/app_colors.dart';
import 'package:prince_academy/core/constants/colors.dart';

class FinancePendingBanner extends StatelessWidget {
  const FinancePendingBanner({
    super.key,
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF3E8DC),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: EColorConstants.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.priority_high_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$count payment${count == 1 ? '' : 's'} waiting for confirmation',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
