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
  final bool includeListPadding;

  const SessionCard({
    super.key,
    required this.booking,
    this.todaySession,
    this.onTap,
    this.compact = false,
    this.includeListPadding = true,
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
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
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
                      _SessionProgressBar(value: progress),
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

    if (!includeListPadding) {
      return card;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: card,
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
          AppColors.activeGreen,
          const Color(0xFFE8F5E9),
        ),
      BookingDisplayStatus.expired => (
          'Expired',
          AppColors.expiredGrey,
          const Color(0xFFF5F5F5),
        ),
      BookingDisplayStatus.completed => (
          'Completed',
          const Color(0xFF1565C0),
          const Color(0xFFE3F2FD),
        ),
      BookingDisplayStatus.pending => (
          'Pending',
          AppColors.pendingOrange,
          const Color(0xFFFFF8E1),
        ),
      BookingDisplayStatus.pendingPayment => (
          'Pending Payment',
          AppColors.pendingOrange,
          const Color(0xFFFFF8E1),
        ),
      BookingDisplayStatus.missed => (
          'Missed',
          AppColors.error,
          const Color(0xFFFFEBEE),
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

class _SessionProgressBar extends StatelessWidget {
  final double value;

  const _SessionProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        height: 6,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey.shade200),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: value.clamp(0.0, 1.0),
                child: const SizedBox.expand(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xFFB7E27A),
                          Color(0xFF8FD15B),
                          Color(0xFF66BE47),
                          Color(0xFF3E9F34),
                        ],
                        stops: [0.0, 0.35, 0.68, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
