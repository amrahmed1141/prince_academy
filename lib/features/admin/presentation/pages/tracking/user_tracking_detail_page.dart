import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/helpers/subscription_formatters.dart';
import 'package:prince_academy/features/admin/data/models/admin_scan_profile_model.dart';
import 'package:prince_academy/features/admin/data/models/payment_verification_data.dart';
import 'package:prince_academy/features/admin/data/repositories/coach_repository.dart';
import 'package:prince_academy/features/admin/presentation/pages/payment_verification_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/session_detail_page.dart';
import 'package:prince_academy/features/admin/presentation/widgets/member_booking_card.dart';

class UserTrackingDetailPage extends StatefulWidget {
  final String userId;
  final String initialName;
  final String? phone;

  const UserTrackingDetailPage({
    super.key,
    required this.userId,
    required this.initialName,
    this.phone,
  });

  @override
  State<UserTrackingDetailPage> createState() => _UserTrackingDetailPageState();
}

class _UserTrackingDetailPageState extends State<UserTrackingDetailPage> {
  static const _successGreen = Color(0xFF2E7D32);

  bool _isLoading = true;
  String? _error;
  List<AdminScanProfile> _bookings = [];
  final Set<String> _busyBookingIds = {};

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bookings =
          await sl<CoachRepository>().getUserScanProfiles(widget.userId);

      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  int get _todaySessionCount =>
      _bookings.where((b) => b.canMarkAttendanceToday).length;

  int get _activeCount => _bookings.where((b) => b.isActive).length;

  int get _expiredCount => _bookings
      .where((b) => !b.isActive && !b.needsPaymentVerification)
      .length;

  int get _pendingCount =>
      _bookings.where((b) => b.needsPaymentVerification).length;

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

    setState(() => _busyBookingIds.add(booking.bookingId));

    try {
      await sl<CoachRepository>().markAttendance(
        bookingId: booking.bookingId,
        userId: widget.userId,
        coachId: booking.coachId,
        adminId: adminId,
      );

      if (!mounted) return;

      setState(() {
        final bookingIdx = _bookings.indexWhere(
          (b) => b.bookingId == booking.bookingId,
        );
        if (bookingIdx != -1) {
          final current = _bookings[bookingIdx];
          _bookings[bookingIdx] = current.copyWith(
            alreadyCheckedInToday: true,
            attendedSessions: current.attendedSessions + 1,
            remainingSessions: current.remainingSessions > 0
                ? current.remainingSessions - 1
                : 0,
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Attendance marked for ${booking.coachName}'),
            ],
          ),
          backgroundColor: _successGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busyBookingIds.remove(booking.bookingId));
      }
    }
  }

  Future<void> _openPaymentVerification(AdminScanProfile booking) async {
    final verified = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PaymentVerificationPage(
          data: PaymentVerificationData.fromScanProfile(booking),
        ),
      ),
    );

    if (verified == true) {
      await _loadBookings();
    }
  }

  Future<void> _openSessionDetail(AdminScanProfile booking) async {
    final refreshed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SessionDetailPage(
          bookingId: booking.bookingId,
          coachName: booking.coachName,
          coachSpecialty: booking.coachSpecialty?.trim().isNotEmpty == true
              ? booking.coachSpecialty!
              : 'MMA',
          sessionTime: booking.selectedTime,
          branchName: booking.branchName,
        ),
      ),
    );

    if (refreshed == true) {
      await _loadBookings();
    }
  }

  String get _initials {
    final name = widget.initialName.trim();
    if (name.isEmpty) return '?';
    return name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase())
        .take(2)
        .join();
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
                ? _ErrorBody(message: _error!, onRetry: _loadBookings)
                : RefreshIndicator(
                    color: EColorConstants.primaryColor,
                    onRefresh: _loadBookings,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        SliverToBoxAdapter(child: _buildHeader()),
                        SliverToBoxAdapter(child: _buildTodaySummary()),
                        const SliverToBoxAdapter(child: SizedBox(height: 12)),
                        if (_bookings.isEmpty)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(
                                child: Text(
                                  'No bookings found for this member.',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: EColorConstants.authPlaceholderGray,
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final booking = _bookings[index];
                                final cardData =
                                    MemberBookingCardData.fromScanProfile(
                                  booking,
                                );

                                return MemberBookingCard(
                                  data: cardData,
                                  isMarkingAttendance: _busyBookingIds
                                      .contains(booking.bookingId),
                                  onMarkAttendance: booking.canMarkAttendanceToday
                                      ? () => _markAttendance(booking)
                                      : null,
                                  onPaymentTap: booking.needsPaymentVerification
                                      ? () => _openPaymentVerification(booking)
                                      : null,
                                  onViewSessions: () =>
                                      _openSessionDetail(booking),
                                );
                              },
                              childCount: _bookings.length,
                            ),
                          ),
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildTodaySummary() {
    final todayName = SubscriptionFormatters.weekdayName(DateTime.now());
    final sessionCount = _todaySessionCount;
    final headerText = sessionCount == 0
        ? 'No sessions scheduled for today'
        : 'Today: $todayName — $sessionCount session${sessionCount == 1 ? '' : 's'} scheduled';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Text(
        headerText,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: sessionCount == 0
              ? EColorConstants.authPlaceholderGray
              : EColorConstants.authTextDarkBrown,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final summaryParts = <String>[
      '${_bookings.length} booking${_bookings.length == 1 ? '' : 's'}',
      '$_activeCount active',
      if (_pendingCount > 0) '$_pendingCount pending payment',
      '$_expiredCount expired',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                color: EColorConstants.authTextDarkBrown,
              ),
              Expanded(
                child: Text(
                  widget.initialName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: EColorConstants.authTextDarkBrown,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: EColorConstants.primaryColor.withOpacity(0.15),
                child: Text(
                  _initials,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: EColorConstants.primaryColor,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.phone != null && widget.phone!.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(
                            Iconsax.call,
                            size: 14,
                            color: EColorConstants.authPlaceholderGray,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.phone!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: EColorConstants.authPlaceholderGray,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      summaryParts.join(' · '),
                      style: const TextStyle(
                        fontSize: 12,
                        color: EColorConstants.authPlaceholderGray,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBody({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.warning_2, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
