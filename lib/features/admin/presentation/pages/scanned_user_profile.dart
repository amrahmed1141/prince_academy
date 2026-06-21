import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/helpers/subscription_formatters.dart';
import 'package:prince_academy/features/admin/data/models/admin_scan_profile_model.dart';
import 'package:prince_academy/features/admin/data/repositories/coach_repository.dart';

class ScannedUserProfilePage extends StatefulWidget {
  final String qrCode;

  const ScannedUserProfilePage({
    super.key,
    required this.qrCode,
  });
 
  @override
  State<ScannedUserProfilePage> createState() => _ScannedUserProfilePageState();
}

class _ScannedUserProfilePageState extends State<ScannedUserProfilePage> {
  static const _successGreen = Color(0xFF2E7D32);
  static const _expiredRed = Color(0xFFD32F2F);

  bool _isLoading = true;
  String? _error;
  List<AdminScanProfile> _bookings = [];
  final Set<String> _busyBookingIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  List<AdminScanProfile> _deduplicateBookings(List<AdminScanProfile> allProfiles) {
    final seen = <String>{};
    return allProfiles.where((profile) => seen.add(profile.bookingId)).toList();
  }

  String _displayName(AdminScanProfile profile) {
    final rawName = profile.fullName.trim();
    if (rawName.isNotEmpty) return rawName;
    return 'Unknown Member';
  }

  String _displayPhone(AdminScanProfile profile) {
    final rawPhone = profile.phone?.trim();
    if (rawPhone != null && rawPhone.isNotEmpty) return rawPhone;
    return 'No phone on file';
  }

  String _initials(String displayName) {
    if (displayName == 'Unknown Member') return '?';
    return displayName
        .trim()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase())
        .take(2)
        .join();
  }

  int get _todaySessionCount =>
      _bookings.where((booking) => booking.isScheduledToday).length;

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final allProfiles =
          await sl<CoachRepository>().getUserByQrCode(widget.qrCode);
      if (allProfiles.isEmpty) {
        throw Exception('Member not found for this QR code.');
      }

      if (!mounted) return;
      setState(() {
        _bookings = _deduplicateBookings(allProfiles);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _markAttendance(AdminScanProfile booking) async {
    if (_busyBookingIds.contains(booking.bookingId)) return;

    final adminId = Supabase.instance.client.auth.currentUser?.id;
    if (adminId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin session expired. Please sign in again.'),
        ),
      );
      return;
    }

    final idx =
        _bookings.indexWhere((entry) => entry.bookingId == booking.bookingId);
    AdminScanProfile? previousEntry;
    if (idx != -1) {
      previousEntry = _bookings[idx];
    }

    setState(() {
      _busyBookingIds.add(booking.bookingId);
      if (idx != -1) {
        final current = _bookings[idx];
        _bookings[idx] = current.copyWith(
          alreadyCheckedInToday: true,
          attendedSessions: current.attendedSessions + 1,
          remainingSessions: current.remainingSessions > 0
              ? current.remainingSessions - 1
              : 0,
        );
      }
    });

    try {
      await sl<CoachRepository>().markAttendance(
        bookingId: booking.bookingId,
        userId: booking.userId,
        coachId: booking.coachId,
        adminId: adminId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text('Attendance marked for ${booking.coachName}'),
            ],
          ),
          backgroundColor: _successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(12),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (idx != -1 && previousEntry != null) {
          _bookings[idx] = previousEntry;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark attendance: $e'),
          backgroundColor: Colors.red.shade500,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(12),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busyBookingIds.remove(booking.bookingId));
      }
    }
  }

  Future<void> _handleRenew(AdminScanProfile booking) async {
    if (_busyBookingIds.contains(booking.bookingId)) return;

    setState(() => _busyBookingIds.add(booking.bookingId));

    try {
      await sl<CoachRepository>().renewSubscription(booking.bookingId);
      if (!mounted) return;

      await _loadData();
      if (!mounted) return;

      final updated = _bookings.firstWhere(
        (p) => p.bookingId == booking.bookingId,
        orElse: () => booking,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Subscription renewed until ${SubscriptionFormatters.formatRenewedUntil(updated.subscriptionEnd)}',
          ),
          backgroundColor: _successGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: _expiredRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busyBookingIds.remove(booking.bookingId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EColorConstants.authFieldBackground,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: EColorConstants.primaryColor,
                ),
              )
            : _error != null
                ? _buildErrorState()
                : RefreshIndicator(
                    color: EColorConstants.primaryColor,
                    onRefresh: _loadData,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back),
                          ),
                        ),
                        _buildHeader(),
                        const SizedBox(height: 18),
                        _buildTodaySummary(),
                        const SizedBox(height: 18),
                        ..._bookings.map((booking) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _BookingCard(
                              booking: booking,
                              isBusy:
                                  _busyBookingIds.contains(booking.bookingId),
                              onMarkAttendance: () => _markAttendance(booking),
                              onRenew: () => _handleRenew(booking),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Unable to load member profile',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: EColorConstants.primaryColor,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final profile = _bookings.first;
    final displayName = _displayName(profile);
    final displayPhone = _displayPhone(profile);
    final initials = _initials(displayName);

    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: EColorConstants.primaryColor,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: EColorConstants.authTextDarkBrown,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                displayPhone,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: EColorConstants.authPlaceholderGray,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTodaySummary() {
    final todayName = SubscriptionFormatters.weekdayName(DateTime.now());
    final sessionCount = _todaySessionCount;
    final headerText = sessionCount == 0
        ? 'No sessions scheduled for today'
        : 'Today: $todayName — $sessionCount session${sessionCount == 1 ? '' : 's'} scheduled';

    return Text(
      headerText,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: sessionCount == 0
                ? EColorConstants.authPlaceholderGray
                : EColorConstants.authTextDarkBrown,
          ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.isBusy,
    required this.onMarkAttendance,
    required this.onRenew,
  });

  final AdminScanProfile booking;
  final bool isBusy;
  final VoidCallback onMarkAttendance;
  final VoidCallback onRenew;

  static const _successGreen = Color(0xFF2E7D32);
  static const _expiredRed = Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    final isActive = booking.subscriptionStatus == 'active';
    final isToday = booking.isScheduledToday && isActive;
    final borderColor = isToday ? _successGreen : Colors.grey.shade200;
    final borderWidth = isToday ? 1.5 : 1.0;
    final bodySmall = Theme.of(context).textTheme.bodySmall;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coach name row with status dot and badge
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    // Green/Red dot based on active/expired status
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isActive ? _successGreen : _expiredRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        booking.coachLabel,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: EColorConstants.authTextDarkBrown,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(isActive: isActive),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${SubscriptionFormatters.formatDays(booking.selectedDays)} · ${booking.selectedTime ?? 'Time not set'}',
            style: bodySmall?.copyWith(
              color: EColorConstants.authPlaceholderGray,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          // Start date in yellow
          if (booking.subscriptionStart != null)
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  'Start: ${SubscriptionFormatters.formatDate(booking.subscriptionStart)}',
                  style: bodySmall?.copyWith(
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          if (booking.subscriptionStart != null) const SizedBox(height: 4),
          // Expires date
          if (booking.subscriptionEnd != null)
            Row(
              children: [
                Icon(
                  isActive ? Icons.timer_outlined : Icons.warning_amber_rounded,
                  size: 14,
                  color: isActive ? EColorConstants.authPlaceholderGray : _expiredRed,
                ),
                const SizedBox(width: 6),
                Text(
                  'Expires: ${SubscriptionFormatters.formatDate(booking.subscriptionEnd)} (${booking.daysRemaining} days)',
                  style: bodySmall?.copyWith(
                    color: isActive ? _successGreen : _expiredRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          if (booking.totalSessions > 0) ...[
            const SizedBox(height: 14),
            _SessionProgressBar(
              attended: booking.attendedSessions,
              total: booking.totalSessions,
            ),
          ],
          if (booking.isScheduledToday && isActive) ...[
            const SizedBox(height: 14),
            const Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: _successGreen,
                  size: 18,
                ),
                SizedBox(width: 6),
                Text(
                  'Scheduled for TODAY',
                  style: TextStyle(
                    color: _successGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (isBusy || booking.alreadyCheckedInToday)
                    ? null
                    : onMarkAttendance,
                icon: Icon(
                  booking.alreadyCheckedInToday
                      ? Icons.check_circle
                      : Icons.how_to_reg_outlined,
                  size: 18,
                ),
                label: Text(
                  booking.alreadyCheckedInToday
                      ? 'Already checked in ✓'
                      : 'Mark Attended',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: booking.alreadyCheckedInToday
                      ? Colors.grey.shade300
                      : EColorConstants.primaryColor,
                  foregroundColor: booking.alreadyCheckedInToday
                      ? EColorConstants.authPlaceholderGray
                      : Colors.white,
                  disabledBackgroundColor: Colors.grey.shade200,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
          if (!isActive) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                onPressed: isBusy ? null : onRenew,
                style: ElevatedButton.styleFrom(
                  backgroundColor: EColorConstants.primaryColor,
                  disabledBackgroundColor: EColorConstants.authPlaceholderGray,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Renew Subscription',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SessionProgressBar extends StatelessWidget {
  const _SessionProgressBar({
    required this.attended,
    required this.total,
  });

  final int attended;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? attended / total : 0.0;
    final bodySmall = Theme.of(context).textTheme.bodySmall;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: bodySmall?.copyWith(
                color: EColorConstants.authPlaceholderGray,
              ),
            ),
            Text(
              '$attended / $total',
              style: bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(
              EColorConstants.primaryColor,
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.amber.shade700 : const Color(0xFFD32F2F);
    final bgColor = isActive ? Colors.amber.shade50 : const Color(0xFFD32F2F).withOpacity(0.12);
    final borderColor = isActive ? Colors.amber.shade200 : const Color(0xFFD32F2F).withOpacity(0.35);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        isActive ? 'Active' : 'Expired',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}