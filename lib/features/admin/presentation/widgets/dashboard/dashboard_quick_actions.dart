import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';

class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({
    super.key,
    this.onScan,
    this.onTracking,
    this.onAddCoach,
    this.onAddSession,
  });

  final VoidCallback? onScan;
  final VoidCallback? onTracking;
  final VoidCallback? onAddCoach;
  final VoidCallback? onAddSession;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick actions',
          style: TextStyle(
            color: EColorConstants.authTextDarkBrown,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionChip(
                icon: Iconsax.scan_barcode,
                label: 'Scan',
                onTap: onScan,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionChip(
                icon: Iconsax.chart,
                label: 'Tracking',
                onTap: onTracking,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionChip(
                icon: Iconsax.personalcard,
                label: 'Add Coach',
                onTap: onAddCoach,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionChip(
                icon: Iconsax.calendar_add,
                label: 'Add Session',
                onTap: onAddSession,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: EColorConstants.primaryColor),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: EColorConstants.authTextDarkBrown,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
