import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_section_card.dart';

class DashboardKpiGrid extends StatelessWidget {
  const DashboardKpiGrid({
    super.key,
    required this.pendingCount,
    required this.todayRevenue,
    required this.activeMembers,
    required this.todaySessions,
    this.onPendingTap,
    this.onRevenueTap,
    this.onMembersTap,
    this.onTodayTap,
  });

  final int pendingCount;
  final double todayRevenue;
  final int activeMembers;
  final int todaySessions;
  final VoidCallback? onPendingTap;
  final VoidCallback? onRevenueTap;
  final VoidCallback? onMembersTap;
  final VoidCallback? onTodayTap;

  static final _currency = NumberFormat.currency(
    locale: 'en',
    symbol: 'EGP ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiTile(
                icon: Iconsax.wallet_money,
                label: 'Pending',
                value: '$pendingCount',
                accent: const Color(0xFFE65100),
                onTap: onPendingTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiTile(
                icon: Iconsax.chart_1,
                label: 'Today revenue',
                value: _currency.format(todayRevenue),
                accent: EColorConstants.primaryColor,
                onTap: onRevenueTap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _KpiTile(
                icon: Iconsax.people,
                label: 'Active members',
                value: '$activeMembers',
                accent: EColorConstants.authDeepPrimary,
                onTap: onMembersTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiTile(
                icon: Iconsax.calendar_1,
                label: "Today's sessions",
                value: '$todaySessions',
                accent: EColorConstants.authLightPrimary,
                onTap: onTodayTap,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      borderRadius: 18,
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: accent),
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: EColorConstants.authTextDarkBrown,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: EColorConstants.authPlaceholderGray,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
