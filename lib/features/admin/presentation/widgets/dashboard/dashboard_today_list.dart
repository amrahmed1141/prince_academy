import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/helpers/class_type_colors.dart';
import 'package:prince_academy/core/helpers/session_live_status.dart';
import 'package:prince_academy/core/l10n/app_strings.dart';
import 'package:prince_academy/features/admin/data/models/admin_dashboard_model.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_section_card.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';

class DashboardTodayList extends StatefulWidget {
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
  State<DashboardTodayList> createState() => _DashboardTodayListState();
}

class _DashboardTodayListState extends State<DashboardTodayList> {
  static const _cardWidth = 280.0;
  static const _cardHeight = 92.0;
  static const _liveCardHeight = 118.0;
  static const _gap = 12.0;

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
    final s = context.s;
    final visible = SessionLiveStatusHelper.currentAndUpcoming(
      widget.sessions,
      now: _now,
    );
    final hasLive = visible.any(
      (session) => SessionLiveStatusHelper.resolve(session, now: _now).isLive,
    );
    final title = widget.sessions.isEmpty
        ? s.currentSession
        : hasLive
            ? s.currentSession
            : s.upcomingSession;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: EColorConstants.authTextDarkBrown,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            if (widget.sessions.isNotEmpty)
              TextButton(
                onPressed: widget.onSeeAll,
                style: TextButton.styleFrom(
                  foregroundColor: EColorConstants.primaryColor,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  s.viewAll,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.sessions.isEmpty)
          _EmptyCard(
            title: s.noSessionsToday,
            subtitle: s.t('destTodaySessionsSub'),
          )
        else if (visible.isEmpty)
          _EmptyCard(
            title: s.allSessionsFinished,
            subtitle: s.t('destTodaySessionsSub'),
          )
        else
          SizedBox(
            height: hasLive ? _liveCardHeight : _cardHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: visible.length,
              cacheExtent: _cardWidth * 3,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              primary: false,
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: true,
              itemBuilder: (context, index) {
                final session = visible[index];
                final status =
                    SessionLiveStatusHelper.resolve(session, now: _now);
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == visible.length - 1 ? 0 : _gap,
                  ),
                  child: SizedBox(
                    width: _cardWidth,
                    child: _TodaySessionCard(
                      key: ValueKey(session.sessionId),
                      session: session,
                      status: status,
                      onTap: widget.onSessionTap == null
                          ? null
                          : () => widget.onSessionTap!(session),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
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
          Text(
            title,
            style: const TextStyle(
              color: EColorConstants.authTextDarkBrown,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: EColorConstants.authPlaceholderGray,
              fontSize: 13,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

class _TodaySessionCard extends StatelessWidget {
  const _TodaySessionCard({
    super.key,
    required this.session,
    required this.status,
    this.onTap,
  });

  final DashboardTodaySession session;
  final SessionLiveStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final time = (session.sessionTime == null || session.sessionTime!.isEmpty)
        ? 'Time TBD'
        : session.sessionTime!;
    final type = (session.sessionType == null || session.sessionType!.isEmpty)
        ? 'Session'
        : session.sessionType!;
    final branch =
        (session.branchName == null || session.branchName!.isEmpty)
            ? 'No branch'
            : session.branchName!;

    return AdminSectionCard(
      borderRadius: 18,
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CoachAvatar(
                  coachName: session.coachName,
                  photoUrl: session.coachPhoto,
                  size: 40,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        session.coachName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: EColorConstants.authTextDarkBrown,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$type · $time',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ClassTypeColors.foreground(type),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        branch,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: EColorConstants.authPlaceholderGray,
                          fontSize: 10,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      if (status.isLive) ...[
                        const SizedBox(height: 6),
                        _AttendanceProgressBar(
                          attended: session.attendedCount,
                          booked: session.bookedCount,
                          progress: session.attendanceProgress,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                _StatusChip(status: status),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttendanceProgressBar extends StatelessWidget {
  const _AttendanceProgressBar({
    required this.attended,
    required this.booked,
    required this.progress,
  });

  final int attended;
  final int booked;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$attended from $booked members',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: EColorConstants.authTextDarkBrown,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: const Color(0xFFE8E0D8),
            color: EColorConstants.primaryColor,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final SessionLiveStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(status.phase);
    return Container(
      constraints: const BoxConstraints(maxWidth: 88),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
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
          fontSize: 9,
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
