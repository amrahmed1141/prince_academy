import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/widgets/shimmer_widgets.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/helpers/subscription_formatters.dart';
import 'package:prince_academy/features/admin/data/models/admin_scan_profile_model.dart';
import 'package:prince_academy/features/admin/data/repositories/coach_repository.dart';
import 'package:prince_academy/features/admin/presentation/pages/session_detail_page.dart';
import 'package:prince_academy/features/admin/presentation/widgets/member_booking_card.dart';

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

  bool _isLoading = true;
  String? _error;
  List<AdminScanProfile> _bookings = [];
  final Set<String> _busyBookingIds = {};
  String? _selectedCoachId;

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

  int _activeCount() =>
      _bookings.where((b) => b.subscriptionStatus.toLowerCase() == 'active').length;

  int _expiredCount() =>
      _filteredBookings.where((b) => b.subscriptionStatus.toLowerCase() == 'expired').length;

  List<AdminScanProfile> get _filteredBookings {
    if (_selectedCoachId == null) return _bookings;
    return _bookings.where((b) => b.coachId == _selectedCoachId).toList();
  }

  List<({String coachId, String coachName, String specialty})> get _uniqueCoaches {
    final seen = <String>{};
    final coaches = <({String coachId, String coachName, String specialty})>[];
    for (final booking in _bookings) {
      if (seen.add(booking.coachId)) {
        coaches.add((
          coachId: booking.coachId,
          coachName: booking.coachName,
          specialty: booking.coachSpecialty?.trim().isNotEmpty == true
              ? booking.coachSpecialty!
              : 'MMA',
        ));
      }
    }
    return coaches;
  }

  int get _todaySessionCount =>
      _filteredBookings.where((b) => b.isScheduledToday && b.isActive).length;

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

  MemberBookingCardData _toCardData(AdminScanProfile booking) {
    return MemberBookingCardData(
      bookingId: booking.bookingId,
      coachName: booking.coachName,
      coachPhoto: booking.coachPhoto,
      specialty: booking.coachSpecialty?.trim().isNotEmpty == true
          ? booking.coachSpecialty!
          : 'MMA',
      branchName: booking.branchName,
      selectedDays: booking.selectedDays,
      selectedTime: booking.selectedTime,
      subscriptionStart: booking.subscriptionStart,
      subscriptionEnd: booking.subscriptionEnd,
      daysRemaining: booking.daysRemaining,
      attendedSessions: booking.attendedSessions,
      totalSessions: booking.totalSessions,
      subscriptionStatus: booking.subscriptionStatus,
      isScheduledToday: booking.isScheduledToday,
      alreadyCheckedInToday: booking.alreadyCheckedInToday,
    );
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
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Attendance marked for ${booking.coachName}'),
            ],
          ),
          backgroundColor: _successGreen,
          behavior: SnackBarBehavior.floating,
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
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busyBookingIds.remove(booking.bookingId));
      }
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
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EColorConstants.authFieldBackground,
      body: SafeArea(
        child: _isLoading
            ? const ScannedProfileShimmer()
            : _error != null
                ? _buildErrorState()
                : RefreshIndicator(
                    color: EColorConstants.primaryColor,
                    onRefresh: _loadData,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        SliverToBoxAdapter(child: _buildHeader()),
                        SliverToBoxAdapter(child: _buildCoachFilterChips()),
                        SliverToBoxAdapter(child: _buildTodaySummary()),
                        const SliverToBoxAdapter(child: SizedBox(height: 12)),
                        if (_filteredBookings.isEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Center(
                                child: Text(
                                  'No bookings match this filter.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final booking = _filteredBookings[index];
                                return MemberBookingCard(
                                  data: _toCardData(booking),
                                  isMarkingAttendance:
                                      _busyBookingIds.contains(booking.bookingId),
                                  onMarkAttendance: booking.isScheduledToday &&
                                          booking.isActive
                                      ? () => _markAttendance(booking)
                                      : null,
                                  onViewSessions: () => _openSessionDetail(booking),
                                );
                              },
                              childCount: _filteredBookings.length,
                            ),
                          ),
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildCoachFilterChips() {
    final coaches = _uniqueCoaches;
    if (coaches.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SELECT BOOKING',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: EColorConstants.authPlaceholderGray,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 72,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _CoachFilterChip(
                  label: 'All',
                  subtitle: 'Bookings',
                  isSelected: _selectedCoachId == null,
                  onTap: () => setState(() => _selectedCoachId = null),
                ),
                ...coaches.map(
                  (coach) => _CoachFilterChip(
                    label: coach.coachName,
                    subtitle: coach.specialty,
                    isSelected: _selectedCoachId == coach.coachId,
                    onTap: () => setState(() => _selectedCoachId = coach.coachId),
                  ),
                ),
              ],
            ),
          ),
        ],
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

  void _handleBack() {
    Navigator.of(context).pop();
  }

  Widget _buildHeader() {
    final profile = _bookings.first;
    final displayName = _displayName(profile);
    final displayPhone = _displayPhone(profile);
    final initials = _initials(displayName);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _handleBack,
                icon: const Icon(Icons.arrow_back),
                color: EColorConstants.authTextDarkBrown,
              ),
              Expanded(
                child: Text(
                  displayName,
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
                backgroundColor: EColorConstants.primaryColor,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                            displayPhone,
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
                    Text(
                      '${_bookings.length} booking${_bookings.length == 1 ? '' : 's'} · '
                      '${_activeCount()} active · ${_expiredCount()} expired',
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

class _CoachFilterChip extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _CoachFilterChip({
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 100,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? EColorConstants.primaryColor.withOpacity(0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? EColorConstants.primaryColor
                  : EColorConstants.authFieldBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected)
                const Icon(
                  Icons.check,
                  size: 14,
                  color: EColorConstants.primaryColor,
                ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? EColorConstants.primaryColor
                      : EColorConstants.authTextDarkBrown,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 9,
                  color: EColorConstants.authPlaceholderGray,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
