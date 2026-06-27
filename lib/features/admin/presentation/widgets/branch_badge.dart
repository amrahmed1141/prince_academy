import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';

class BranchBadge extends StatelessWidget {
  final String? branchName;

  const BranchBadge({super.key, this.branchName});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: EColorConstants.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 12,
              color: EColorConstants.primaryColor,
            ),
            const SizedBox(width: 4),
            Text(
              branchName ?? 'No Branch',
              style: const TextStyle(
                fontSize: 11,
                color: EColorConstants.primaryColor,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
