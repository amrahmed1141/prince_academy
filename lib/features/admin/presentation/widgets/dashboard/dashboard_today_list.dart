import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/data/models/admin_dashboard_model.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_section_card.dart';

class DashboardTodayList extends StatelessWidget {
  const DashboardTodayList({
    super.key,
    required this.sessions,
    this.onSeeAll,
    this.onSessionTap,
  });

  final List<DashboardTodaySession> sessions;
  final VoidCallback? onSeeAll;
  final ValueChanged<DashboardTodaySession>? onSessionTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Today at the academy',
                style: TextStyle(
                  color: EColorConstants.authTextDarkBrown,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            if (sessions.isNotEmpty)
              TextButton(
                onPressed: onSeeAll,
                style: TextButton.styleFrom(
                  foregroundColor: EColorConstants.primaryColor,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'View all',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (sessions.isEmpty)
          AdminSectionCard(
            borderRadius: 18,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            child: Column(
              children: [
                Icon(
                  Iconsax.calendar_remove,
                  size: 36,
                  color: EColorConstants.authPlaceholderGray.withOpacity(0.8),
                ),
                const SizedBox(height: 10),
                const Text(
                  'No sessions today',
                  style: TextStyle(
                    color: EColorConstants.authTextDarkBrown,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Check-ins will show up here when members train.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: EColorConstants.authPlaceholderGray,
                    fontSize: 13,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          )
        else
          AdminSectionCard(
            borderRadius: 18,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < sessions.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: EColorConstants.authFieldBorder,
                    ),
                  _TodayRow(
                    session: sessions[i],
                    onTap: () => onSessionTap?.call(sessions[i]),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _TodayRow extends StatelessWidget {
  const _TodayRow({
    required this.session,
    this.onTap,
  });

  final DashboardTodaySession session;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final time = (session.selectedTime == null || session.selectedTime!.isEmpty)
        ? 'Time TBD'
        : session.selectedTime!;
    final statusColor = session.alreadyCheckedIn
        ? const Color(0xFF2E7D32)
        : EColorConstants.authLightPrimary;
    final statusLabel = session.alreadyCheckedIn ? 'Checked in' : 'Expected';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  session.alreadyCheckedIn
                      ? Iconsax.tick_circle
                      : Iconsax.clock,
                  size: 18,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.memberName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: EColorConstants.authTextDarkBrown,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${session.coachName} · $time',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: EColorConstants.authPlaceholderGray,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
