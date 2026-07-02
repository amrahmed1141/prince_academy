import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/app_colors.dart';
import 'package:prince_academy/core/helpers/subscription_formatters.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';
import 'package:prince_academy/features/booking/data/models/booking_history_model.dart';
import 'package:prince_academy/features/sessions/data/models/session_model.dart';
import 'package:prince_academy/features/sessions/domain/weekly_progress_calculator.dart';
import 'package:prince_academy/features/sessions/domain/weekly_progress_summary.dart';

class SessionCard extends StatelessWidget {
  final BookingHistoryModel booking;
  final TodaySessionInfo? todaySession;
  final VoidCallback? onTap;
  final bool compact;

  const SessionCard({
    super.key,
    required this.booking,
    this.todaySession,
    this.onTap,
    this.compact = false,
  });

  factory SessionCard.fromSession(
    Session session, {
    BookingHistoryModel? booking,
    TodaySessionInfo? todaySession,
    VoidCallback? onTap,
    bool compact = false,
  }) {
    return SessionCard(
      booking: booking ?? _bookingFromSession(session),
      todaySession: todaySession,
      onTap: onTap,
      compact: compact,
    );
  }

  static BookingHistoryModel bookingFromSession(Session session) =>
      _bookingFromSession(session);

  static BookingHistoryModel _bookingFromSession(Session session) {
    return BookingHistoryModel(
      bookingId: session.bookingId,
      userId: '',
      coachId: session.coachId,
      coachName: session.coachName,
      coachPhoto: session.coachPhoto,
      coachSpecialty: session.coachSpecialty,
      branchName: session.branchName,
      selectedDays: session.dayName.trim().isNotEmpty
          ? [session.dayName.trim()]
          : const [],
      selectedTime: session.selectedTime,
      attendedSessions: session.attendedSessions,
      totalSessions: session.totalSessions,
      displayStatus: session.isCompleted
          ? 'completed'
          : session.isMissed
              ? 'missed'
              : 'active',
    );
  }

  int _daysRemaining(DateTime? end) {
    if (end == null) return 0;
    final now = DateTime.now();
    final endDay = DateTime(end.year, end.month, end.day);
    final today = DateTime(now.year, now.month, now.day);
    return endDay.difference(today).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final schedule = SubscriptionFormatters.formatDays(booking.selectedDays);
    final time = booking.selectedTime?.trim().isNotEmpty == true
        ? booking.selectedTime!
        : 'Time not set';
    final daysRemaining = _daysRemaining(booking.subscriptionEnd);
    final displayStatus =
        WeeklyProgressCalculator.resolveDisplayStatus(booking);
    final isExpired = displayStatus == BookingDisplayStatus.expired;
    final progress = booking.totalSessions > 0
        ? (booking.attendedSessions / booking.totalSessions).clamp(0.0, 1.0)
        : 0.0;
    final hasToday = todaySession != null;

    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: hasToday && todaySession!.alreadyAttended == false
            ? Border.all(
                color: AppColors.primary.withOpacity(0.28),
                width: 1.2,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: hasToday
                ? AppColors.primary.withOpacity(0.12)
                : Colors.black.withOpacity(0.08),
            blurRadius: hasToday ? 22 : 20,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: compact
                ? const EdgeInsets.fromLTRB(14, 14, 14, 12)
                : const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                    if (hasToday) ...[
                      _TodaySessionPanel(info: todaySession!),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CoachAvatar(
                          coachName: booking.coachName,
                          photoUrl: booking.coachPhoto,
                          size: 52,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      booking.coachName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                  _StatusBadge(status: displayStatus),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                booking.coachSpecialty?.isNotEmpty == true
                                    ? booking.coachSpecialty!
                                    : 'MMA',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$schedule · $time',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (booking.subscriptionStart != null) ...[
                      const SizedBox(height: 10),
                      _MetaRow(
                        icon: Iconsax.calendar_1,
                        text:
                            'Start: ${SubscriptionFormatters.formatDate(booking.subscriptionStart)}',
                      ),
                    ],
                    if (booking.subscriptionEnd != null) ...[
                      const SizedBox(height: 4),
                      _MetaRow(
                        icon: isExpired ? Iconsax.warning_2 : Iconsax.timer_1,
                        text: isExpired
                            ? 'Expired: ${SubscriptionFormatters.formatDate(booking.subscriptionEnd)}'
                            : 'Expires: ${SubscriptionFormatters.formatDate(booking.subscriptionEnd)} (${daysRemaining.clamp(0, 9999)} days)',
                        color: isExpired
                            ? const Color(0xFFD32F2F)
                            : const Color(0xFF2E7D32),
                      ),
                    ],
                    if (booking.totalSessions > 0) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Sessions',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          Text(
                            '${booking.attendedSessions} / ${booking.totalSessions}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                          minHeight: 5,
                        ),
                      ),
                    ],
                    if (onTap != null) ...[
                      SizedBox(height: compact ? 8 : 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _ViewSessionLink(onTap: onTap!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );

    if (compact) {
      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: UnconstrainedBox(
          constrainedAxis: Axis.horizontal,
          alignment: Alignment.topLeft,
          clipBehavior: Clip.none,
          child: SizedBox(
            width: 320,
            child: card,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: card,
    );
  }
}

class _TodaySessionPanel extends StatefulWidget {
  final TodaySessionInfo info;

  const _TodaySessionPanel({required this.info});

  @override
  State<_TodaySessionPanel> createState() => _TodaySessionPanelState();
}

class _TodaySessionPanelState extends State<_TodaySessionPanel>
    with TickerProviderStateMixin {
  late final AnimationController _expandController;
  late final AnimationController _pulseController;
  late final Animation<double> _expandAnimation;
  late final Animation<double> _pulseAnimation;
  bool _manualExpanded = true;

  TodaySessionInfo get info => widget.info;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _pulseAnimation = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _expandController.value = 1.0;

    if (!info.alreadyAttended) {
      _startBreathingLoop();
    }
  }

  Future<void> _startBreathingLoop() async {
    while (mounted && !info.alreadyAttended) {
      await Future<void>.delayed(const Duration(seconds: 3));
      if (!mounted || info.alreadyAttended) break;
      if (_manualExpanded) {
        await _expandController.reverse();
        _manualExpanded = false;
      }
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted || info.alreadyAttended) break;
      if (!_manualExpanded) {
        await _expandController.forward();
        _manualExpanded = true;
      }
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggle() {
    if (info.alreadyAttended) return;
    setState(() {
      _manualExpanded = !_manualExpanded;
      if (_manualExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  String get _headline {
    if (info.alreadyAttended) {
      return 'You trained with ${info.coachName} today';
    }
    return 'You have a ${info.coachName} session today';
  }

  String get _subtitle {
    if (info.alreadyAttended) {
      return 'Great work — checked in at ${info.time}';
    }
    return 'Today at ${info.time} · See you at the gym';
  }

  @override
  Widget build(BuildContext context) {
    final attended = info.alreadyAttended;
    final accent = attended ? const Color(0xFF2E7D32) : AppColors.primary;

    return GestureDetector(
      onTap: attended ? null : _toggle,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([_expandAnimation, _pulseAnimation]),
        builder: (context, child) {
          final expanded = _expandAnimation.value > 0.15;
          final expandT = _expandAnimation.value;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: attended
                    ? [
                        const Color(0xFFE8F5E9),
                        const Color(0xFFF1F8E9),
                      ]
                    : [
                        AppColors.primary.withOpacity(0.14 + expandT * 0.06),
                        AppColors.primary.withOpacity(0.06 + expandT * 0.04),
                      ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: accent.withOpacity(
                  attended ? 0.45 : 0.25 + _pulseAnimation.value * 0.35,
                ),
                width: 1.2,
              ),
              boxShadow: attended
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.primary
                            .withOpacity(0.08 * _pulseAnimation.value),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: (1 - expandT).clamp(0.0, 1.0),
                    child: SizedBox(
                      height: (1 - expandT) * 40,
                      child: expandT > 0.92
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  _LiveDot(
                                    color: accent,
                                    pulse: _pulseAnimation.value,
                                    show: !attended,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      attended
                                          ? '${info.coachName} session done'
                                          : 'Session today · ${info.time}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: accent,
                                        fontFamily: 'Poppins',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (!attended)
                                    Icon(
                                      expanded
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                      size: 18,
                                      color: accent,
                                    ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  SizeTransition(
                    sizeFactor: _expandAnimation,
                    axisAlignment: -1,
                    child: FadeTransition(
                      opacity: _expandAnimation,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                attended
                                    ? Icons.check_rounded
                                    : Iconsax.flash_1,
                                size: 18,
                                color: accent,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _headline,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: attended
                                          ? const Color(0xFF1B5E20)
                                          : AppColors.textPrimary,
                                      fontFamily: 'Poppins',
                                      height: 1.25,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _subtitle,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: attended
                                          ? const Color(0xFF2E7D32)
                                          : Colors.grey.shade700,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LiveDot extends StatelessWidget {
  final Color color;
  final double pulse;
  final bool show;

  const _LiveDot({
    required this.color,
    required this.pulse,
    required this.show,
  });

  @override
  Widget build(BuildContext context) {
    if (!show) {
      return Icon(Icons.check_circle, size: 14, color: color);
    }

    return Container(
      width: 8 + pulse * 4,
      height: 8 + pulse * 4,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.25 + pulse * 0.35),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Center(
        child: Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final BookingDisplayStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (status) {
      BookingDisplayStatus.active => (
          'Active',
          const Color(0xFF2E7D32),
          const Color(0xFFE8F5E9),
        ),
      BookingDisplayStatus.expired => (
          'Expired',
          const Color(0xFFD32F2F),
          const Color(0xFFFFEBEE),
        ),
      BookingDisplayStatus.completed => (
          'Completed',
          const Color(0xFF1565C0),
          const Color(0xFFE3F2FD),
        ),
      BookingDisplayStatus.pending => (
          'Pending',
          const Color(0xFFF9A825),
          const Color(0xFFFFF8E1),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const _MetaRow({
    required this.icon,
    required this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 13,
          color: color ?? Colors.grey.shade500,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color ?? AppColors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }
}

class _ViewSessionLink extends StatelessWidget {
  final VoidCallback onTap;

  const _ViewSessionLink({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'view session',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(width: 2),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
