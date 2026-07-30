import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/helpers/class_type_colors.dart';
import 'package:prince_academy/core/helpers/session_live_status.dart';
import 'package:prince_academy/features/admin/data/models/admin_dashboard_model.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_section_card.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';

class TodaySessionCard extends StatefulWidget {
  const TodaySessionCard({
    super.key,
    required this.session,
    this.onTap,
  });

  final DashboardTodaySession session;
  final VoidCallback? onTap;

  @override
  State<TodaySessionCard> createState() => _TodaySessionCardState();
}

class _TodaySessionCardState extends State<TodaySessionCard> {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final status = SessionLiveStatusHelper.resolve(session, now: _now);
    final time = session.sessionTime?.trim();
    final type = session.sessionType?.trim();
    final branch = session.branchName?.trim();
    final displayTime = time == null || time.isEmpty ? 'Time TBD' : time;
    final displayType = type == null || type.isEmpty ? 'Session' : type;
    final displayBranch =
        branch == null || branch.isEmpty ? 'No branch assigned' : branch;

    return AdminSectionCard(
      borderRadius: 18,
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                CoachAvatar(
                  coachName: session.coachName,
                  photoUrl: session.coachPhoto,
                  size: 48,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.coachName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: EColorConstants.authTextDarkBrown,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: ClassTypeColors.background(displayType),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$displayType · $displayTime',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color:
                                      ClassTypeColors.foreground(displayType),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Iconsax.location,
                            size: 13,
                            color: Colors.brown.shade300,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              displayBranch,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.brown.shade300,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _LiveStatusChip(status: status),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveStatusChip extends StatelessWidget {
  const _LiveStatusChip({required this.status});

  final SessionLiveStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(status.phase);
    return Container(
      constraints: const BoxConstraints(maxWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: colors.foreground,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          fontFamily: 'Poppins',
          height: 1.2,
        ),
      ),
    );
  }

  static ({Color background, Color foreground}) _colorsFor(
    SessionLivePhase phase,
  ) {
    switch (phase) {
      case SessionLivePhase.startingNow:
        return (
          background: const Color(0xFFFFF3E0),
          foreground: const Color(0xFFE65100),
        );
      case SessionLivePhase.inProgress:
        return (
          background: const Color(0xFFE8F5E9),
          foreground: const Color(0xFF2E7D32),
        );
      case SessionLivePhase.upcoming:
        return (
          background: const Color(0xFFE3F2FD),
          foreground: const Color(0xFF1565C0),
        );
      case SessionLivePhase.finished:
        return (
          background: EColorConstants.authFieldBorder,
          foreground: EColorConstants.authPlaceholderGray,
        );
    }
  }
}
