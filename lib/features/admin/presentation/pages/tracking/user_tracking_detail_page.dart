import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/helpers/subscription_formatters.dart';
import 'package:prince_academy/core/widgets/shimmer_widgets.dart';
import 'package:prince_academy/features/admin/data/models/admin_scan_profile_model.dart';
import 'package:prince_academy/features/admin/data/models/payment_verification_data.dart';
import 'package:prince_academy/features/admin/data/repositories/coach_repository.dart';
import 'package:prince_academy/features/admin/presentation/pages/payment_verification_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/session_detail_page.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_coach_booking_filter_chips.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_member_booking_list_helpers.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_member_profile_header.dart';
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

  late final CoachRepository _repository;
  StreamSubscription<List<AdminScanProfile>>? _profilesSub;

  bool _isLoading = true;
  String? _error;
  List<AdminScanProfile> _bookings = [];
  final Set<String> _busyBookingIds = {};
  String? _selectedCoachId;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _repository = sl<CoachRepository>();

    final cached = _repository.getCachedUserScanProfiles(widget.userId);
    if (cached != null) {
      _bookings = cached;
      _isLoading = false;
    }

    _profilesSub = _repository.watchUserScanProfiles(widget.userId).listen(
      (bookings) {
        if (!mounted) return;
        setState(() {
          _bookings = bookings;
          _isLoading = false;
          _error = null;
        });
      },
      onError: (Object e) {
        if (!mounted) return;
        // Keep showing cached content on background refresh failures.
        if (_bookings.isNotEmpty) return;
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      },
    );
  }

  @override
  void dispose() {
    _profilesSub?.cancel();
    _repository.stopWatchingUserScanProfiles(widget.userId);
    super.dispose();
  }

  Future<void> _reload({bool force = true}) async {
    try {
      await _repository.getUserScanProfiles(widget.userId, force: force);
    } catch (e) {
      if (!mounted) return;
      if (_bookings.isNotEmpty) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  List<AdminScanProfile> get _coachFilteredBookings =>
      filterBookingsByCoach(_bookings, _selectedCoachId);

  List<AdminScanProfile> get _filteredBookings =>
      filterBookingsByStatus(_coachFilteredBookings, _statusFilter);

  List<AdminScanProfile> get _pendingPaymentBookings =>
      pendingPaymentBookings(_filteredBookings);

  List<AdminScanProfile> get _verticalBookings {
    if (_statusFilter == 'pending') return const [];

    final bookings = _statusFilter == null
        ? _filteredBookings
            .where((booking) => !booking.needsPaymentVerification)
            .toList()
        : _filteredBookings;

    return sortMemberBookings(bookings);
  }

  bool get _showPendingSection =>
      _pendingPaymentBookings.isNotEmpty &&
      (_statusFilter == null || _statusFilter == 'pending');

  int get _todaySessionCount =>
      _filteredBookings.where((b) => b.canMarkAttendanceToday).length;

  List<({String coachId, String coachName, String? coachPhoto})> get _uniqueCoaches =>
      uniqueCoachesFromBookings(_bookings);

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
      await _repository.markAttendance(
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
      await _reload(force: true);
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
      await _reload(force: true);
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
            ? const UserTrackingDetailShimmer()
            : _error != null
                ? _ErrorBody(message: _error!, onRetry: () => _reload(force: true))
                : RefreshIndicator(
                    color: EColorConstants.primaryColor,
                    onRefresh: () => _reload(force: true),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        SliverToBoxAdapter(child: _buildHeader()),
                        SliverToBoxAdapter(child: _buildCoachFilterChips()),
                        const SliverToBoxAdapter(child: SizedBox(height: 12)),
                        if (_filteredBookings.isEmpty)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(
                                child: Text(
                                  'No bookings match this filter.',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: EColorConstants.authPlaceholderGray,
                                  ),
                                ),
                              ),
                            ),
                          )
                        else ...[
                          if (_showPendingSection) ...[
                            const SliverToBoxAdapter(
                              child: AdminBookingSectionHeader(
                                title: 'PENDING PAYMENTS',
                              ),
                            ),
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final booking =
                                      _pendingPaymentBookings[index];
                                  return MemberBookingCard(
                                    data: MemberBookingCardData.fromScanProfile(
                                      booking,
                                    ),
                                    isConfirmingPayment: _busyBookingIds
                                        .contains(booking.bookingId),
                                    onPaymentTap: () =>
                                        _openPaymentVerification(booking),
                                    onViewSessions: () =>
                                        _openSessionDetail(booking),
                                  );
                                },
                                childCount: _pendingPaymentBookings.length,
                              ),
                            ),
                            const SliverToBoxAdapter(child: SizedBox(height: 8)),
                          ],
                          if (_verticalBookings.isNotEmpty) ...[
                            SliverToBoxAdapter(child: _buildTodaySummary()),
                            if (_statusFilter == null)
                              const SliverToBoxAdapter(
                                child: AdminBookingSectionHeader(
                                  title: 'BOOKINGS',
                                ),
                              ),
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final booking = _verticalBookings[index];
                                  final cardData =
                                      MemberBookingCardData.fromScanProfile(
                                    booking,
                                  );

                                  return MemberBookingCard(
                                    data: cardData,
                                    isMarkingAttendance: _busyBookingIds
                                        .contains(booking.bookingId),
                                    onMarkAttendance:
                                        booking.canMarkAttendanceToday
                                            ? () => _markAttendance(booking)
                                            : null,
                                    onPaymentTap:
                                        booking.needsPaymentVerification
                                            ? () =>
                                                _openPaymentVerification(booking)
                                            : null,
                                    onViewSessions: () =>
                                        _openSessionDetail(booking),
                                  );
                                },
                                childCount: _verticalBookings.length,
                              ),
                            ),
                          ],
                        ],
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildCoachFilterChips() {
    return AdminCoachBookingFilterChips(
      coaches: _uniqueCoaches,
      selectedCoachId: _selectedCoachId,
      onSelected: (coachId) => setState(() => _selectedCoachId = coachId),
    );
  }

  Widget _buildTodaySummary() {
    final todayName = SubscriptionFormatters.weekdayName(DateTime.now());
    final sessionCount = _todaySessionCount;
    final headerText = sessionCount == 0
        ? 'No sessions scheduled for today'
        : 'Today: $todayName — $sessionCount session${sessionCount == 1 ? '' : 's'} scheduled';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: sessionCount == 0
            ? Colors.grey.shade100
            : EColorConstants.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: sessionCount == 0
              ? Colors.grey.shade200
              : EColorConstants.primaryColor.withOpacity(0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.event_note,
            size: 18,
            color: sessionCount == 0
                ? Colors.grey.shade600
                : EColorConstants.primaryColor,
          ),
          const SizedBox(width: 10),
          Expanded(
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
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final displayPhone = widget.phone?.trim().isNotEmpty == true
        ? widget.phone!
        : 'No phone on file';

    return AdminMemberProfileHeader(
      onBack: () => Navigator.of(context).pop(),
      displayName: widget.initialName,
      displayPhone: displayPhone,
      initials: _initials,
      totalBookings: _bookings.length,
      activeCount: countActiveBookings(_bookings),
      pendingCount: countPendingBookings(_bookings),
      expiredCount: countExpiredBookings(_bookings),
      statusFilter: _statusFilter,
      onStatusFilterChanged: (filter) => setState(() => _statusFilter = filter),
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
            const Icon(Icons.warning_amber_outlined, size: 40),
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
