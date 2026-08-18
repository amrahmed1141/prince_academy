import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_section_card.dart';
import 'package:prince_academy/features/admin/presentation/widgets/dashboard/today_attendance_kpi_card.dart';

/// Edge bounce + very snappy page settle for the KPI [PageView].
///
/// [PageView] wraps this with [PageScrollPhysics], which reads [spring] from
/// its parent — a stiff spring makes the snap feel fast instead of floaty.
class _FastBouncePagePhysics extends BouncingScrollPhysics {
  const _FastBouncePagePhysics({super.parent});

  @override
  _FastBouncePagePhysics applyTo(ScrollPhysics? ancestor) {
    return _FastBouncePagePhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => SpringDescription.withDampingRatio(
        mass: 0.28,
        stiffness: 520,
        ratio: 1.05,
      );

  /// Stock bouncing physics doubles the fling threshold and feels sluggish.
  @override
  double get minFlingVelocity => kMinFlingVelocity * 0.55;

  @override
  double get dragStartDistanceMotionThreshold => 1.5;
}

/// Swipeable two-page KPI section: Today Attendance + Overview.
class DashboardKpiPager extends StatefulWidget {
  const DashboardKpiPager({
    super.key,
    required this.todayAttended,
    required this.todayBooked,
    required this.todaySessions,
    required this.pendingCount,
    required this.todayRevenue,
    required this.coachesCount,
    required this.membersCount,
    required this.freezePendingCount,
    this.onAttendanceTap,
    this.onPendingTap,
    this.onRevenueTap,
    this.onTodaySessionsTap,
    this.onAllSchedulesTap,
    this.onCoachesTap,
    this.onMembersTap,
    this.onFreezeTap,
  });

  final int todayAttended;
  final int todayBooked;
  final int todaySessions;
  final int pendingCount;
  final double todayRevenue;
  final int coachesCount;
  final int membersCount;
  final int freezePendingCount;
  final VoidCallback? onAttendanceTap;
  final VoidCallback? onPendingTap;
  final VoidCallback? onRevenueTap;
  final VoidCallback? onTodaySessionsTap;
  final VoidCallback? onAllSchedulesTap;
  final VoidCallback? onCoachesTap;
  final VoidCallback? onMembersTap;
  final VoidCallback? onFreezeTap;

  static final _currency = NumberFormat.currency(
    locale: 'en',
    symbol: 'EGP ',
    decimalDigits: 0,
  );

  static const _pageGap = 14.0;

  @override
  State<DashboardKpiPager> createState() => _DashboardKpiPagerState();
}

class _DashboardKpiPagerState extends State<DashboardKpiPager> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // PageView itself never rebuilds on scroll — only the dots listen.
    return Column(
      children: [
        SizedBox(
          height: 340,
          child: NotificationListener<ScrollNotification>(
            // Keep horizontal paging from fighting the parent vertical list.
            onNotification: (notification) =>
                notification.metrics.axis == Axis.horizontal,
            child: PageView(
              controller: _controller,
              physics: const _FastBouncePagePhysics(),
              children: [
                _PageInset(
                  child: _AttendancePage(
                    attended: widget.todayAttended,
                    booked: widget.todayBooked,
                    todaySessions: widget.todaySessions,
                    pendingCount: widget.pendingCount,
                    todayRevenue: widget.todayRevenue,
                    onAttendanceTap: widget.onAttendanceTap,
                    onTodaySessionsTap: widget.onTodaySessionsTap,
                    onPendingTap: widget.onPendingTap,
                    onRevenueTap: widget.onRevenueTap,
                  ),
                ),
                _PageInset(
                  child: _OverviewPage(
                    coachesCount: widget.coachesCount,
                    membersCount: widget.membersCount,
                    freezePendingCount: widget.freezePendingCount,
                    onAllSchedulesTap: widget.onAllSchedulesTap,
                    onCoachesTap: widget.onCoachesTap,
                    onMembersTap: widget.onMembersTap,
                    onFreezeTap: widget.onFreezeTap,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final page = _controller.hasClients
                ? (_controller.page ?? 0)
                : 0.0;
            return _DotsIndicator(page: page, count: 2);
          },
        ),
      ],
    );
  }
}

/// Horizontal inset so adjacent pages show a clear gap while swiping.
class _PageInset extends StatelessWidget {
  const _PageInset({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DashboardKpiPager._pageGap / 2,
      ),
      child: child,
    );
  }
}

class _AttendancePage extends StatelessWidget {
  const _AttendancePage({
    required this.attended,
    required this.booked,
    required this.todaySessions,
    required this.pendingCount,
    required this.todayRevenue,
    this.onAttendanceTap,
    this.onTodaySessionsTap,
    this.onPendingTap,
    this.onRevenueTap,
  });

  final int attended;
  final int booked;
  final int todaySessions;
  final int pendingCount;
  final double todayRevenue;
  final VoidCallback? onAttendanceTap;
  final VoidCallback? onTodaySessionsTap;
  final VoidCallback? onPendingTap;
  final VoidCallback? onRevenueTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Hero(
            tag: TodayAttendanceKpiCard.heroTag,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onAttendanceTap,
                borderRadius: BorderRadius.circular(22),
                child: TodayAttendanceKpiCard(
                  attended: attended,
                  booked: booked,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Iconsax.calendar_1,
                label: "Today's sessions",
                value: '$todaySessions',
                accent: EColorConstants.authLightPrimary,
                onTap: onTodaySessionsTap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                icon: Iconsax.wallet_money,
                label: 'Pending',
                value: '$pendingCount',
                accent: const Color(0xFFE65100),
                onTap: onPendingTap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                icon: Iconsax.chart_1,
                label: 'Today revenue',
                value: DashboardKpiPager._currency.format(todayRevenue),
                accent: EColorConstants.primaryColor,
                onTap: onRevenueTap,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OverviewPage extends StatelessWidget {
  const _OverviewPage({
    required this.coachesCount,
    required this.membersCount,
    required this.freezePendingCount,
    this.onAllSchedulesTap,
    this.onCoachesTap,
    this.onMembersTap,
    this.onFreezeTap,
  });

  final int coachesCount;
  final int membersCount;
  final int freezePendingCount;
  final VoidCallback? onAllSchedulesTap;
  final VoidCallback? onCoachesTap;
  final VoidCallback? onMembersTap;
  final VoidCallback? onFreezeTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: AdminSectionCard(
            borderRadius: 22,
            padding: EdgeInsets.zero,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onAllSchedulesTap,
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 16, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: EColorConstants.primaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Iconsax.calendar_1,
                          size: 26,
                          color: EColorConstants.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'All Schedules',
                              style: TextStyle(
                                color: EColorConstants.authTextDarkBrown,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Every coach's training schedule",
                              style: TextStyle(
                                color: EColorConstants.authPlaceholderGray,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Iconsax.arrow_right_3,
                        size: 20,
                        color: EColorConstants.authPlaceholderGray
                            .withOpacity(0.8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Iconsax.teacher,
                label: 'Coaches',
                value: '$coachesCount',
                accent: EColorConstants.authDeepPrimary,
                onTap: onCoachesTap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                icon: Iconsax.people,
                label: 'Members',
                value: '$membersCount',
                accent: EColorConstants.primaryColor,
                onTap: onMembersTap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                icon: Iconsax.pause_circle,
                label: 'Freeze',
                value: '$freezePendingCount',
                accent: EColorConstants.authLightPrimary,
                onTap: onFreezeTap,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      borderRadius: 18,
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: EColorConstants.authTextDarkBrown,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: EColorConstants.authPlaceholderGray,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 16, color: accent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.page, required this.count});

  final double page;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final distance = (page - index).abs().clamp(0.0, 1.0);
        final selected = 1.0 - distance;
        final size = 6.0 + (selected * 2.0);
        // Plain Container: page already updates every frame; AnimatedContainer
        // stacked another animation and made the slider feel laggy.
        return Container(
          width: size,
          height: size,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.lerp(
              EColorConstants.authPlaceholderGray.withOpacity(0.35),
              EColorConstants.authTextDarkBrown,
              selected,
            ),
          ),
        );
      }),
    );
  }
}
