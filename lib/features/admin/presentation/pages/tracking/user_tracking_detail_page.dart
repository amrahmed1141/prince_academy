import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/helpers/subscription_formatters.dart';
import 'package:prince_academy/features/admin/data/models/coach_model.dart';
import 'package:prince_academy/features/admin/data/models/today_booking_model.dart';
import 'package:prince_academy/features/admin/data/models/user_booking_detail_model.dart';
import 'package:prince_academy/features/admin/data/repositories/coach_repository.dart';
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
  List<UserBookingDetail> _bookings = [];
  List<TodayBooking> _todayBookings = [];
  Map<String, String?> _coachPhotos = {};
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
      final repository = sl<CoachRepository>();
      final results = await Future.wait([
        repository.getUserBookingDetails(widget.userId),
        repository.getTodayBookings(widget.userId),
        repository.fetchCoaches(),
      ]);

      final bookings = results[0] as List<UserBookingDetail>;
      final todayBookings = results[1] as List<TodayBooking>;
      final coaches = results[2] as List<CoachModel>;

      final photoMap = <String, String?>{};
      for (final coach in coaches) {
        photoMap[coach.id] = coach.photoUrl;
      }

      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _todayBookings = todayBookings;
        _coachPhotos = photoMap;
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

  TodayBooking? _todayInfo(String bookingId) {
    for (final today in _todayBookings) {
      if (today.bookingId == bookingId) return today;
    }
    return null;
  }

  int _daysRemaining(DateTime? end) {
    if (end == null) return 0;
    final now = DateTime.now();
    final endOfDay = DateTime(end.year, end.month, end.day);
    final today = DateTime(now.year, now.month, now.day);
    return endOfDay.difference(today).inDays;
  }

  int get _todaySessionCount =>
      _bookings.where((b) => b.isActive && _todayInfo(b.bookingId) != null).length;

  MemberBookingCardData _toCardData(UserBookingDetail booking) {
    final today = _todayInfo(booking.bookingId);
    final coachPhoto =
        booking.coachPhoto ?? _coachPhotos[booking.coachId];

    return MemberBookingCardData(
      bookingId: booking.bookingId,
      coachName: booking.coachName,
      coachPhoto: coachPhoto,
      specialty: booking.coachSpecialty.isNotEmpty
          ? booking.coachSpecialty
          : 'MMA',
      branchName: booking.branchName,
      selectedDays: booking.selectedDays,
      selectedTime: booking.selectedTime,
      subscriptionStart: booking.subscriptionStart,
      subscriptionEnd: booking.subscriptionEnd,
      daysRemaining: _daysRemaining(booking.subscriptionEnd),
      attendedSessions: booking.attendedSessions,
      totalSessions: booking.totalSessions,
      subscriptionStatus: booking.subscriptionStatus,
      isScheduledToday: today != null,
      alreadyCheckedInToday: today?.alreadyCheckedIn ?? false,
    );
  }

  Future<void> _markAttendance(UserBookingDetail booking) async {
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
        final todayIdx = _todayBookings.indexWhere(
          (t) => t.bookingId == booking.bookingId,
        );
        if (todayIdx != -1) {
          _todayBookings[todayIdx] = _todayBookings[todayIdx].copyWith(
            alreadyCheckedIn: true,
          );
        }

        final bookingIdx = _bookings.indexWhere(
          (b) => b.bookingId == booking.bookingId,
        );
        if (bookingIdx != -1) {
          final current = _bookings[bookingIdx];
          _bookings[bookingIdx] = UserBookingDetail(
            bookingId: current.bookingId,
            coachId: current.coachId,
            coachName: current.coachName,
            coachSpecialty: current.coachSpecialty,
            coachPhoto: current.coachPhoto,
            branchId: current.branchId,
            branchName: current.branchName,
            selectedDays: current.selectedDays,
            selectedTime: current.selectedTime,
            subscriptionStart: current.subscriptionStart,
            subscriptionEnd: current.subscriptionEnd,
            totalSessions: current.totalSessions,
            attendedSessions: current.attendedSessions + 1,
            remainingSessions: current.remainingSessions > 0
                ? current.remainingSessions - 1
                : 0,
            subscriptionStatus: current.subscriptionStatus,
            totalPrice: current.totalPrice,
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

  Future<void> _openSessionDetail(UserBookingDetail booking) async {
    final refreshed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SessionDetailPage(
          bookingId: booking.bookingId,
          coachName: booking.coachName,
          coachSpecialty: booking.coachSpecialty.isNotEmpty
              ? booking.coachSpecialty
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

  int get _activeCount => _bookings.where((b) => b.isActive).length;

  int get _expiredCount => _bookings.where((b) => !b.isActive).length;

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
                              final hasTodaySession =
                                  booking.isActive &&
                                  _todayInfo(booking.bookingId) != null;

                              return MemberBookingCard(
                                data: _toCardData(booking),
                                isMarkingAttendance:
                                    _busyBookingIds.contains(booking.bookingId),
                                onMarkAttendance: hasTodaySession
                                    ? () => _markAttendance(booking)
                                    : null,
                                onViewSessions: () => _openSessionDetail(booking),
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
                      '${_bookings.length} booking${_bookings.length == 1 ? '' : 's'} · '
                      '$_activeCount active · $_expiredCount expired',
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
