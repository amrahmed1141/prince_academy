import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/helpers/session_schedule_helper.dart';
import 'package:prince_academy/core/helpers/subscription_formatters.dart';
import 'package:prince_academy/features/admin/data/models/admin_scan_profile_model.dart';
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
  // ADDED: payment fields for admin QR scan
  final String? paymentMethod;
  final String? paymentStatus;
  final double totalPrice;

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
    this.paymentMethod,
    this.paymentStatus,
    this.totalPrice = 0,
  });

  bool get needsPaymentVerification {
    final pay = paymentStatus?.toLowerCase();
    if (pay == 'pending_payment' ||
        pay == 'awaiting_verification' ||
        pay == 'pending') {
      return true;
    }
    final sub = subscriptionStatus.toLowerCase();
    if (sub == 'pending_payment' || sub == 'pending') {
      final verified = pay == 'verified' || pay == 'paid' || pay == 'active';
      return !verified;
    }
    return false;
  }

  bool get _isPastSubscriptionEnd {
    if (subscriptionEnd == null) return false;
    final today = SessionScheduleHelper.dateOnly(DateTime.now());
    final end = SessionScheduleHelper.dateOnly(subscriptionEnd!);
    return today.isAfter(end);
  }

  bool get _isPaymentVerified {
    final pay = paymentStatus?.toLowerCase();
    return pay == 'verified' || pay == 'paid' || pay == 'active';
  }

  bool get isPaidActive {
    if (needsPaymentVerification) return false;
    if (_isPastSubscriptionEnd) return false;
    final sub = subscriptionStatus.toLowerCase();
    if (sub == 'expired' || sub == 'cancelled' || sub == 'rejected') {
      return false;
    }
    if (_isPaymentVerified) return true;
    return sub == 'active' || sub == 'approved';
  }

  bool get hasSessionToday =>
      isScheduledToday ||
      SessionScheduleHelper.isSessionDayOnDate(
        selectedDays: selectedDays,
        subscriptionStart: subscriptionStart,
        subscriptionEnd: subscriptionEnd,
      );

  bool get canMarkAttendanceToday => isPaidActive && hasSessionToday;

  MemberBookingDisplayStatus get displayStatus {
    if (needsPaymentVerification) {
      return MemberBookingDisplayStatus.pending;
    }
    if (totalSessions > 0 && attendedSessions >= totalSessions) {
      return MemberBookingDisplayStatus.completed;
    }
    if (_isPastSubscriptionEnd ||
        subscriptionStatus.toLowerCase() == 'expired') {
      return MemberBookingDisplayStatus.expired;
    }
    if (isPaidActive) return MemberBookingDisplayStatus.active;
    final status = subscriptionStatus.toLowerCase();
    if (status == 'active' || status == 'approved') {
      return MemberBookingDisplayStatus.active;
    }
    if (status == 'pending' || status == 'pending_payment') {
      return MemberBookingDisplayStatus.pending;
    }
    return MemberBookingDisplayStatus.expired;
  }

  factory MemberBookingCardData.fromScanProfile(AdminScanProfile profile) {
    return MemberBookingCardData(
      bookingId: profile.bookingId,
      coachName: profile.coachName,
      coachPhoto: profile.coachPhoto,
      specialty: profile.coachSpecialty?.trim().isNotEmpty == true
          ? profile.coachSpecialty!
          : 'MMA',
      branchName: profile.branchName,
      selectedDays: profile.selectedDays,
      selectedTime: profile.selectedTime,
      subscriptionStart: profile.subscriptionStart,
      subscriptionEnd: profile.subscriptionEnd,
      daysRemaining: profile.daysRemaining,
      attendedSessions: profile.attendedSessions,
      totalSessions: profile.totalSessions,
      subscriptionStatus: profile.subscriptionStatus,
      isScheduledToday: profile.isScheduledToday,
      alreadyCheckedInToday: profile.alreadyCheckedInToday,
      paymentMethod: profile.paymentMethod,
      paymentStatus: profile.paymentStatus,
      totalPrice: profile.totalPrice,
    );
  }
}

class MemberBookingCard extends StatelessWidget {
  final MemberBookingCardData data;
  final VoidCallback onViewSessions;
  final VoidCallback? onMarkAttendance;
  final VoidCallback? onPaymentTap;
  final bool isMarkingAttendance;
  final bool isConfirmingPayment;

  const MemberBookingCard({
    super.key,
    required this.data,
    required this.onViewSessions,
    this.onMarkAttendance,
    this.onPaymentTap,
    this.isMarkingAttendance = false,
    this.isConfirmingPayment = false,
  });

  @override
  Widget build(BuildContext context) {
    final status = data.displayStatus;
    final isExpired = status == MemberBookingDisplayStatus.expired;
    final isPendingPayment = status == MemberBookingDisplayStatus.pending;
    final showMarkAttendance =
        data.canMarkAttendanceToday && onMarkAttendance != null;
    final schedule = SubscriptionFormatters.formatDays(data.selectedDays);
    final time = data.selectedTime?.trim().isNotEmpty == true
        ? data.selectedTime!
        : 'Time not set';

    final cardWidget = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: showMarkAttendance
            ? null
            : Border.all(
                color: EColorConstants.primaryColor.withOpacity(0.12),
                width: 1,
              ),
        boxShadow: showMarkAttendance
            ? null
            : [
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
          if (data.subscriptionStart != null && data.subscriptionEnd != null)
            _InfoRow(
              icon: Iconsax.calendar_1,
              text:
                  'Period: ${SessionScheduleHelper.formatPeriod(data.subscriptionStart!, data.subscriptionEnd!)}',
            ),
          if (data.totalPrice > 0)
            _InfoRow(
              icon: Iconsax.wallet_3,
              text: 'Total: ${data.totalPrice.toStringAsFixed(0)} EGP',
            ),
          if (isPendingPayment)
            _InfoRow(
              icon: Iconsax.timer_1,
              text:
                  'Status: ⏳ Pending Payment (${data.paymentMethod?.toLowerCase() == 'cash' ? 'Cash' : 'InstaPay'})',
              color: const Color(0xFFF9A825),
            )
          else if (data.paymentMethod != null &&
              data.paymentMethod!.trim().isNotEmpty)
            _InfoRow(
              icon: Iconsax.money,
              text:
                  'Payment: ${data.paymentMethod!.toLowerCase() == 'cash' ? 'Cash' : 'InstaPay'} · Verified',
              color: const Color(0xFF2E7D32),
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
                        widthFactor: data.totalSessions > 0
                            ? (data.attendedSessions / data.totalSessions).clamp(0.0, 1.0)
                            : 0.0,
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
          if (isPendingPayment && onPaymentTap != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onViewSessions,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: EColorConstants.primaryColor,
                      side: const BorderSide(
                        color: EColorConstants.authFieldBorder,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'View Sessions',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isConfirmingPayment ? null : onPaymentTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF9A825),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: isConfirmingPayment
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Payment',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ] else ...[
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
        ],
      ),
    );

    if (showMarkAttendance) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: DecoratedBox(
            decoration: const BoxDecoration(
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
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: cardWidget,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: cardWidget,
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
          'Pending Payment',
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
