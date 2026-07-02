import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/app_colors.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/theme/app_gradients.dart';
import 'package:prince_academy/core/constants/text.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/features/admin/data/models/branch_model.dart';
import 'package:prince_academy/features/booking/data/models/booking_history_model.dart';
import 'package:prince_academy/features/home/presentation/bloc/home_bloc.dart';
import 'package:prince_academy/features/home/presentation/bloc/home_event.dart';
import 'package:prince_academy/features/home/presentation/bloc/home_state.dart';
import 'package:prince_academy/features/home/presentation/pages/home/widgets/category_list.dart';
import 'package:prince_academy/features/home/presentation/pages/home/widgets/coaches_list.dart';
import 'package:prince_academy/features/home/presentation/pages/home/widgets/searchbar.dart';
import 'package:prince_academy/features/home/presentation/widgets/calendar_strip.dart';
import 'package:prince_academy/features/sessions/data/models/session_model.dart';
import 'package:prince_academy/features/sessions/domain/weekly_progress_calculator.dart';
import 'package:prince_academy/features/sessions/presentation/pages/user_session_detail_page.dart';
import 'package:prince_academy/features/sessions/presentation/widgets/session_card.dart';
import 'package:prince_academy/features/sessions/presentation/widgets/weekly_attendance_chart.dart';
import 'package:shimmer/shimmer.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<HomeBloc>()..add(const LoadHomeData()),
      child: const _HomePageBody(),
    );
  }
}

class _HomePageBody extends StatefulWidget {
  const _HomePageBody();

  @override
  State<_HomePageBody> createState() => _HomePageBodyState();
}

class _HomePageBodyState extends State<_HomePageBody> {
  final ValueNotifier<String?> _selectedCategoryNotifier =
      ValueNotifier<String?>('All');

  @override
  void dispose() {
    _selectedCategoryNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppGradients.sessionsScreenDecoration(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ETexts.appBarTitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                ETexts.appBarSubTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[100],
                ),
                child: const Icon(Iconsax.notification, size: 20),
              ),
              onPressed: () {},
            ),
          ],
        ),
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            context.read<HomeBloc>().add(const LoadHomeData());
            await context.read<HomeBloc>().stream.firstWhere(
                  (s) => !s.isLoading,
                );
          },
          child: CustomScrollView(
            cacheExtent: 600,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              const SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16),
                    HomeSearchBar(),
                    SizedBox(height: 16),
                  ],
                ),
              ),

              // INSERT: date strip, carousel, empty state
              BlocSelector<HomeBloc, HomeState, _HomeSectionsViewData>(
                selector: (state) => _HomeSectionsViewData(
                  isLoading: state.isLoading,
                  selectedDate: state.selectedDate,
                  allSessions: state.allSessions,
                  sessionsForSelectedDate: state.sessionsForSelectedDate,
                  upcomingSession: state.upcomingSession,
                  bookings: state.bookings,
                  lastBooking: state.lastBooking,
                  branch: state.branch,
                  hasSessionsForSelectedDate: state.hasSessionsForSelectedDate,
                ),
                builder: (context, data) {
                  if (data.isLoading) {
                    return const SliverToBoxAdapter(
                      child: _HomeSectionsShimmer(),
                    );
                  }

                  return SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: CalendarStrip(
                          selectedDate: data.selectedDate,
                          allSessions: data.allSessions,
                          onDateSelected: (date) {
                            context.read<HomeBloc>().add(SelectDate(date));
                          },
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                      SliverToBoxAdapter(
                        child: _HomeInsightsCarousel(
                          selectedDate: data.selectedDate,
                          allSessions: data.allSessions,
                          sessionsForSelectedDate: data.sessionsForSelectedDate,
                          bookings: data.bookings,
                          onBookingTap: (booking) =>
                              _openSessionDetail(context, booking),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  );
                },
              ),
              // END INSERT

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Category',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: CategoryList(
                  selectedCategoryNotifier: _selectedCategoryNotifier,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Choose Your Coach',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                      ),
                      TextButton(
                        onPressed: () {
                          _selectedCategoryNotifier.value = 'All';
                        },
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            color: EColorConstants.primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                sliver: CoachesList(
                  selectedCategoryNotifier: _selectedCategoryNotifier,
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 110),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSessionDetail(BuildContext context, BookingHistoryModel booking) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => UserSessionDetailPage(
          bookingId: booking.bookingId,
          coachName: booking.coachName,
          coachSpecialty: booking.coachSpecialty?.isNotEmpty == true
              ? booking.coachSpecialty!
              : 'MMA',
          sessionTime: booking.selectedTime,
          branchName: booking.branchName,
        ),
      ),
    );
  }
}

class _HomeSectionsViewData {
  final bool isLoading;
  final DateTime selectedDate;
  final List<Session> allSessions;
  final List<Session> sessionsForSelectedDate;
  final Session? upcomingSession;
  final List<BookingHistoryModel> bookings;
  final BookingHistoryModel? lastBooking;
  final Branch? branch;
  final bool hasSessionsForSelectedDate;

  const _HomeSectionsViewData({
    required this.isLoading,
    required this.selectedDate,
    required this.allSessions,
    required this.sessionsForSelectedDate,
    required this.upcomingSession,
    required this.bookings,
    required this.lastBooking,
    required this.branch,
    required this.hasSessionsForSelectedDate,
  });

  @override
  bool operator ==(Object other) {
    return other is _HomeSectionsViewData &&
        other.isLoading == isLoading &&
        other.selectedDate == selectedDate &&
        other.sessionsForSelectedDate.length ==
            sessionsForSelectedDate.length &&
        other.upcomingSession?.bookingId == upcomingSession?.bookingId &&
        other.upcomingSession?.sessionDate == upcomingSession?.sessionDate &&
        other.bookings.length == bookings.length &&
        other.lastBooking?.bookingId == lastBooking?.bookingId &&
        other.branch?.id == branch?.id &&
        other.hasSessionsForSelectedDate == hasSessionsForSelectedDate &&
        other.allSessions.length == allSessions.length;
  }

  @override
  int get hashCode => Object.hash(
        isLoading,
        selectedDate,
        sessionsForSelectedDate.length,
        upcomingSession?.bookingId,
        bookings.length,
        lastBooking?.bookingId,
        branch?.id,
        hasSessionsForSelectedDate,
        allSessions.length,
      );
}

class _HomeInsightsCarousel extends StatelessWidget {
  final DateTime selectedDate;
  final List<Session> allSessions;
  final List<Session> sessionsForSelectedDate;
  final List<BookingHistoryModel> bookings;
  final void Function(BookingHistoryModel booking) onBookingTap;

  const _HomeInsightsCarousel({
    required this.selectedDate,
    required this.allSessions,
    required this.sessionsForSelectedDate,
    required this.bookings,
    required this.onBookingTap,
  });

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  BookingHistoryModel _bookingForSession(Session session) {
    for (final booking in bookings) {
      if (booking.bookingId == session.bookingId) {
        return booking;
      }
    }
    return SessionCard.bookingFromSession(session);
  }

  Session? _sessionOnSelectedDate() {
    if (sessionsForSelectedDate.isEmpty) return null;
    final sorted = List<Session>.from(sessionsForSelectedDate)
      ..sort((a, b) => a.selectedTime.compareTo(b.selectedTime));
    final preferred =
        sorted.where((s) => s.isToday || s.isUpcoming).toList(growable: false);
    return preferred.isNotEmpty ? preferred.first : sorted.first;
  }

  /// Nearest upcoming session strictly after [selectedDate] (next day first).
  Session? _nextSessionAfterSelectedDate() {
    final anchor = _dateOnly(selectedDate);
    final candidates = allSessions
        .where((s) {
          if (!(s.isUpcoming || s.isToday)) return false;
          return _dateOnly(s.sessionDate).isAfter(anchor);
        })
        .toList()
      ..sort((a, b) {
        final dateCompare = a.sessionDate.compareTo(b.sessionDate);
        if (dateCompare != 0) return dateCompare;
        return a.selectedTime.compareTo(b.selectedTime);
      });

    if (candidates.isEmpty) return null;

    final nearestDay = _dateOnly(candidates.first.sessionDate);
    final onNearestDay = candidates
        .where((s) => _isSameDay(_dateOnly(s.sessionDate), nearestDay))
        .toList()
      ..sort((a, b) => a.selectedTime.compareTo(b.selectedTime));
    return onNearestDay.first;
  }

  int _itemCount({
    required Session? sessionOnSelectedDate,
    required Session? nextUpcoming,
    required bool showProgress,
  }) {
    final hasSelectedSession = sessionOnSelectedDate != null;
    final hasUpcoming = nextUpcoming != null;
    if (hasSelectedSession) {
      return 1 + (hasUpcoming ? 1 : 0) + (showProgress ? 1 : 0);
    }
    return (hasUpcoming ? 1 : 0) + (showProgress ? 1 : 0);
  }

  Widget _buildSessionCard(Session session, {bool showTodayBanner = false}) {
    final booking = _bookingForSession(session);
    final todaySession = showTodayBanner
        ? WeeklyProgressCalculator.todaySessionForBooking(booking, allSessions)
        : null;

    return SessionCard(
      booking: booking,
      todaySession: todaySession,
      onTap: () => onBookingTap(booking),
      compact: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionOnSelectedDate = _sessionOnSelectedDate();
    final nextUpcoming = _nextSessionAfterSelectedDate();
    final weeklyProgress = WeeklyProgressCalculator.calculate(
      bookings: bookings,
      sessions: allSessions,
    );
    final showProgress = weeklyProgress.days.isNotEmpty;
    final itemCount = _itemCount(
      sessionOnSelectedDate: sessionOnSelectedDate,
      nextUpcoming: nextUpcoming,
      showProgress: showProgress,
    );

    if (itemCount == 0) {
      return const SizedBox.shrink();
    }

    final isTodaySelected = _isSameDay(
      _dateOnly(selectedDate),
      _dateOnly(DateTime.now()),
    );

    return SizedBox(
      height: 300,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        primary: false,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        clipBehavior: Clip.none,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          final hasSelectedSession = sessionOnSelectedDate != null;
          final hasUpcoming = nextUpcoming != null;

          if (hasSelectedSession && index == 0) {
            return RepaintBoundary(
              child: _buildSessionCard(
                sessionOnSelectedDate,
                showTodayBanner: isTodaySelected,
              ),
            );
          }

          final upcomingIndex = hasSelectedSession ? 1 : 0;
          if (hasUpcoming && index == upcomingIndex) {
            return RepaintBoundary(
              child: _buildSessionCard(nextUpcoming),
            );
          }

          return RepaintBoundary(
            child: UnconstrainedBox(
              constrainedAxis: Axis.horizontal,
              alignment: Alignment.topLeft,
              clipBehavior: Clip.none,
              child: SizedBox(
                width: MediaQuery.sizeOf(context).width - 32,
                child: WeeklyAttendanceChart(summary: weeklyProgress),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HomeSectionsShimmer extends StatelessWidget {
  const _HomeSectionsShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            primary: false,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 7,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, __) => Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                width: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            primary: false,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, __) => Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                width: 280,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
