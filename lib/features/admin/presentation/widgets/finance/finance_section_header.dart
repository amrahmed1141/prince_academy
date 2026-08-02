import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/app_colors.dart';
import 'package:prince_academy/core/constants/colors.dart';

class FinanceSectionHeader extends StatelessWidget {
  const FinanceSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: EColorConstants.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
