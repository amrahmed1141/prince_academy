import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/helpers/subscription_formatters.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';

enum MemberBookingDisplayStatus { active, expired, pending, completed }

class MemberBookingCardData {
  final String bookingId;
  final String coachName;
  final String? coachPhoto;
  final String specialty;
  final String? branchName;
  final List<String> selectedDays;
  final String? selectedTime;
  final DateTime? subscriptionStart;
  final DateTime? subscriptionEnd;
  final int daysRemaining;
  final int attendedSessions;
  final int totalSessions;
  final String subscriptionStatus;
  final bool isScheduledToday;
  final bool alreadyCheckedInToday;

  const MemberBookingCardData({
    required this.bookingId,
    required this.coachName,
    this.coachPhoto,
    required this.specialty,
    this.branchName,
    this.selectedDays = const [],
    this.selectedTime,
    this.subscriptionStart,
    this.subscriptionEnd,
    this.daysRemaining = 0,
    this.attendedSessions = 0,
    this.totalSessions = 0,
    required this.subscriptionStatus,
    this.isScheduledToday = false,
    this.alreadyCheckedInToday = false,
  });

  MemberBookingDisplayStatus get displayStatus {
    final status = subscriptionStatus.toLowerCase();
    if (totalSessions > 0 && attendedSessions >= totalSessions) {
      return MemberBookingDisplayStatus.completed;
    }
    if (status == 'pending') return MemberBookingDisplayStatus.pending;
    if (status == 'expired') return MemberBookingDisplayStatus.expired;
    if (status == 'active') return MemberBookingDisplayStatus.active;
    return MemberBookingDisplayStatus.expired;
  }
}

class MemberBookingCard extends StatelessWidget {
  final MemberBookingCardData data;
  final VoidCallback onViewSessions;
  final VoidCallback? onMarkAttendance;
  final bool isMarkingAttendance;

  const MemberBookingCard({
    super.key,
    required this.data,
    required this.onViewSessions,
    this.onMarkAttendance,
    this.isMarkingAttendance = false,
  });

  @override
  Widget build(BuildContext context) {
    final status = data.displayStatus;
    final isExpired = status == MemberBookingDisplayStatus.expired;
    final isActive = status == MemberBookingDisplayStatus.active;
    final showMarkAttendance =
        isActive && data.isScheduledToday && onMarkAttendance != null;
    final schedule = SubscriptionFormatters.formatDays(data.selectedDays);
    final time = data.selectedTime?.trim().isNotEmpty == true
        ? data.selectedTime!
        : 'Time not set';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: showMarkAttendance
              ? const Color(0xFF2E7D32)
              : EColorConstants.primaryColor.withOpacity(0.12),
          width: showMarkAttendance ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CoachAvatar(
                coachName: data.coachName,
                photoUrl: data.coachPhoto,
                size: 56,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _StatusDot(status: status),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${data.coachName} · ${data.specialty}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: EColorConstants.authTextDarkBrown,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$schedule · $time',
                      style: const TextStyle(
                        fontSize: 12,
                        color: EColorConstants.authPlaceholderGray,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: status),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),
          if (data.branchName != null && data.branchName!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(
                    Iconsax.location,
                    size: 14,
                    color: EColorConstants.authPlaceholderGray,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      data.branchName!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: EColorConstants.authTextDarkBrown,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (!isExpired && data.subscriptionStart != null) ...[
            _InfoRow(
              icon: Iconsax.calendar_1,
              text:
                  'Start: ${SubscriptionFormatters.formatDate(data.subscriptionStart)}',
            ),
            const SizedBox(height: 4),
          ],
          if (data.subscriptionEnd != null)
            _InfoRow(
              icon: isExpired ? Iconsax.warning_2 : Iconsax.timer_1,
              text: isExpired
                  ? 'Expired: ${SubscriptionFormatters.formatDate(data.subscriptionEnd)}'
                  : 'Expires: ${SubscriptionFormatters.formatDate(data.subscriptionEnd)} (${data.daysRemaining} days)',
              color: isExpired
                  ? const Color(0xFFD32F2F)
                  : const Color(0xFF2E7D32),
            ),
          if (data.totalSessions > 0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Progress',
                  style: TextStyle(
                    fontSize: 12,
                    color: EColorConstants.authPlaceholderGray,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  '${data.attendedSessions} / ${data.totalSessions}',
                  style: const TextStyle(
                    fontSize: 12,
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
                value: data.totalSessions > 0
                    ? (data.attendedSessions / data.totalSessions).clamp(0.0, 1.0)
                    : 0,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  status == MemberBookingDisplayStatus.completed
                      ? const Color(0xFF2E7D32)
                      : EColorConstants.primaryColor,
                ),
                minHeight: 6,
              ),
            ),
          ],
          if (showMarkAttendance) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.event_available_outlined,
                  size: 16,
                  color: Color(0xFF2E7D32),
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Scheduled for TODAY',
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (isMarkingAttendance || data.alreadyCheckedInToday)
                    ? null
                    : onMarkAttendance,
                icon: isMarkingAttendance
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        data.alreadyCheckedInToday
                            ? Icons.check_circle
                            : Icons.how_to_reg_outlined,
                      ),
                label: Text(
                  data.alreadyCheckedInToday
                      ? 'Already checked in ✓'
                      : 'Mark Attended',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: data.alreadyCheckedInToday
                      ? Colors.grey.shade300
                      : EColorConstants.primaryColor,
                  foregroundColor: data.alreadyCheckedInToday
                      ? EColorConstants.authPlaceholderGray
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onViewSessions,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Sessions',
                    style: TextStyle(
                      color: EColorConstants.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: EColorConstants.primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const _InfoRow({
    required this.icon,
    required this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color ?? EColorConstants.authPlaceholderGray),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color ?? EColorConstants.authTextDarkBrown,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  final MemberBookingDisplayStatus status;

  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      MemberBookingDisplayStatus.active => const Color(0xFF2E7D32),
      MemberBookingDisplayStatus.expired => const Color(0xFFD32F2F),
      MemberBookingDisplayStatus.pending => const Color(0xFFF9A825),
      MemberBookingDisplayStatus.completed => const Color(0xFF1565C0),
    };

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final MemberBookingDisplayStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (status) {
      MemberBookingDisplayStatus.active => (
          'Active',
          const Color(0xFF2E7D32),
          const Color(0xFFE8F5E9),
        ),
      MemberBookingDisplayStatus.expired => (
          'Expired',
          const Color(0xFFD32F2F),
          const Color(0xFFFFEBEE),
        ),
      MemberBookingDisplayStatus.pending => (
          'Pending',
          const Color(0xFFF9A825),
          const Color(0xFFFFF8E1),
        ),
      MemberBookingDisplayStatus.completed => (
          'Completed',
          const Color(0xFF1565C0),
          const Color(0xFFE3F2FD),
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
