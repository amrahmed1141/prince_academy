import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/theme/app_gradients.dart';
import 'package:prince_academy/core/constants/text.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/widgets/branded_pull_to_refresh.dart';
import 'package:prince_academy/core/widgets/offline_banner.dart';
import 'package:prince_academy/features/admin/data/models/branch_model.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';
import 'package:prince_academy/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:prince_academy/features/auth/presentation/bloc/auth_state.dart';
import 'package:prince_academy/features/booking/data/models/booking_history_model.dart';
import 'package:prince_academy/features/home/presentation/bloc/home_bloc.dart';
import 'package:prince_academy/features/home/presentation/bloc/home_event.dart';
import 'package:prince_academy/features/home/presentation/bloc/home_state.dart';
import 'package:prince_academy/core/widgets/app_search_bar.dart';
import 'package:prince_academy/core/search/search_query_cubit.dart';
import 'package:prince_academy/features/home/presentation/pages/home/widgets/category_list.dart';
import 'package:prince_academy/features/home/presentation/pages/home/widgets/coaches_list.dart';
import 'package:prince_academy/features/home/presentation/widgets/calendar_strip.dart';
import 'package:prince_academy/features/home/presentation/widgets/first_time_booking_card.dart';
import 'package:prince_academy/features/home/presentation/pages/coaches_page.dart';
import 'package:prince_academy/features/notifications/presentation/widgets/notification_bell_button.dart';
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
  late final SearchQueryCubit _searchQueryCubit;

  @override
  void initState() {
    super.initState();
    _searchQueryCubit = SearchQueryCubit();
  }

  @override
  void dispose() {
    _selectedCategoryNotifier.dispose();
    _searchQueryCubit.close();
    super.dispose();
  }

  void _openCoachesPage() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const CoachesPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _searchQueryCubit,
      child: Container(
      decoration: AppGradients.homeScreenDecoration(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: 12,
          title: BlocSelector<AuthBloc, AuthState, _HomeGreetingData>(
            selector: (state) {
              if (state is AuthAuthed) {
                final name = state.user.fullName?.trim();
                return _HomeGreetingData(
                  fullName: (name != null && name.isNotEmpty) ? name : 'Member',
                  photoUrl: state.user.avatarUrl,
                );
              }
              return const _HomeGreetingData(
                fullName: 'Member',
                photoUrl: null,
              );
            },
            builder: (context, greeting) {
              return Row(
                children: [
                  CoachAvatar(
                    coachName: greeting.fullName,
                    photoUrl: greeting.photoUrl,
                    size: 44,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ETexts.appBarTitle,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          greeting.fullName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            const NotificationBellButton(),
          ],
        ),
        body: BrandedPullToRefresh(
          onRefresh: () async {
            context.read<HomeBloc>().add(const LoadHomeData(forceRefresh: true));
            await context.read<HomeBloc>().stream.firstWhere(
                  (s) => !s.isRefreshing && !s.isLoading,
                );
          },
          child: CustomScrollView(
            cacheExtent: 600,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              BlocSelector<HomeBloc, HomeState, bool>(
                selector: (s) => s.error != null && s.hasLoaded,
                builder: (context, showOffline) {
                  if (!showOffline) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  return const SliverToBoxAdapter(child: OfflineBanner());
                },
              ),
              BlocSelector<HomeBloc, HomeState, bool>(
                selector: (s) => s.isRefreshing && s.hasLoaded,
                builder: (context, refreshing) {
                  return SliverToBoxAdapter(
                    child: SilentRefreshBar(visible: refreshing),
                  );
                },
              ),
              const SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8),
                    QuerySearchBar(
                      hintText: 'Search For Coaches, Classes, or Events',
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              ),

              // INSERT: date strip, carousel, empty state
              BlocSelector<HomeBloc, HomeState, _HomeSectionsViewData>(
                selector: (state) => _HomeSectionsViewData(
                  isLoading: state.isLoading,
                  hasLoaded: state.hasLoaded,
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
                  if (data.isLoading && !data.hasLoaded) {
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
                      const SliverToBoxAdapter(child: SizedBox(height: 8)),
                      SliverToBoxAdapter(
                        child: _HomeInsightsCarousel(
                          selectedDate: data.selectedDate,
                          allSessions: data.allSessions,
                          sessionsForSelectedDate:
                              data.sessionsForSelectedDate,
                          bookings: data.bookings,
                          // NEW: first-time CTA when no active/upcoming sessions
                          showFirstTimeBookingCard:
                              data.showFirstTimeBookingCard,
                          onBookCoach: _openCoachesPage,
                          onBookingTap: (booking) =>
                              _openSessionDetail(context, booking),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 4)),
                    ],
                  );
                },
              ),
              // END INSERT

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
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
                        onPressed: _openCoachesPage,
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
                  searchQueryCubit: _searchQueryCubit,
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 110),
              ),
            ],
          ),
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

class _HomeGreetingData {
  final String fullName;
  final String? photoUrl;

  const _HomeGreetingData({
    required this.fullName,
    required this.photoUrl,
  });

  @override
  bool operator ==(Object other) {
    return other is _HomeGreetingData &&
        other.fullName == fullName &&
        other.photoUrl == photoUrl;
  }

  @override
  int get hashCode => Object.hash(fullName, photoUrl);
}

class _HomeSectionsViewData {
  final bool isLoading;
  final bool hasLoaded;
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
    required this.hasLoaded,
    required this.selectedDate,
    required this.allSessions,
    required this.sessionsForSelectedDate,
    required this.upcomingSession,
    required this.bookings,
    required this.lastBooking,
    required this.branch,
    required this.hasSessionsForSelectedDate,
  });

  // NEW: first-time users = no upcoming sessions and no active bookings
  bool get showFirstTimeBookingCard {
    if (!hasLoaded || isLoading) return false;
    if (upcomingSession != null) return false;

    final hasActiveBooking = bookings.any((booking) {
      final status = booking.effectiveDisplayStatus.toLowerCase();
      return status == 'active' ||
          status == 'pending' ||
          status == 'pending_payment';
    });
    return !hasActiveBooking;
  }

  @override
  bool operator ==(Object other) {
    return other is _HomeSectionsViewData &&
        other.isLoading == isLoading &&
        other.hasLoaded == hasLoaded &&
        other.selectedDate == selectedDate &&
        other.sessionsForSelectedDate.length ==
            sessionsForSelectedDate.length &&
        other.upcomingSession?.bookingId == upcomingSession?.bookingId &&
        other.upcomingSession?.sessionDate == upcomingSession?.sessionDate &&
        other.bookings.length == bookings.length &&
        other.lastBooking?.bookingId == lastBooking?.bookingId &&
        other.branch?.id == branch?.id &&
        other.hasSessionsForSelectedDate == hasSessionsForSelectedDate &&
        other.allSessions.length == allSessions.length &&
        // NEW: include first-time flag so BlocSelector rebuilds correctly
        other.showFirstTimeBookingCard == showFirstTimeBookingCard;
  }

  @override
  int get hashCode => Object.hash(
        isLoading,
        hasLoaded,
        selectedDate,
        sessionsForSelectedDate.length,
        upcomingSession?.bookingId,
        bookings.length,
        lastBooking?.bookingId,
        branch?.id,
        hasSessionsForSelectedDate,
        allSessions.length,
        showFirstTimeBookingCard, // NEW
      );
}

class _HomeInsightsCarousel extends StatelessWidget {
  final DateTime selectedDate;
  final List<Session> allSessions;
  final List<Session> sessionsForSelectedDate;
  final List<BookingHistoryModel> bookings;
  // NEW
  final bool showFirstTimeBookingCard;
  final VoidCallback onBookCoach;
  final void Function(BookingHistoryModel booking) onBookingTap;

  const _HomeInsightsCarousel({
    required this.selectedDate,
    required this.allSessions,
    required this.sessionsForSelectedDate,
    required this.bookings,
    required this.showFirstTimeBookingCard, // NEW
    required this.onBookCoach, // NEW
    required this.onBookingTap,
  });

  BookingHistoryModel _bookingForSession(Session session) {
    for (final booking in bookings) {
      if (booking.bookingId == session.bookingId) {
        return booking;
      }
    }
    return SessionCard.bookingFromSession(session);
  }

  List<Session> _sessionsForSelectedDay() {
    if (sessionsForSelectedDate.isEmpty) return const [];
    final sorted = List<Session>.from(sessionsForSelectedDate)
      ..sort((a, b) => a.selectedTime.compareTo(b.selectedTime));
    return sorted;
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
    final daySessions = _sessionsForSelectedDay();
    final weeklyProgress = WeeklyProgressCalculator.calculate(
      bookings: bookings,
      sessions: allSessions,
    );
    final showProgress = weeklyProgress.days.isNotEmpty;
    final isTodaySelected = HomeBloc.isSameDay(
      selectedDate,
      HomeBloc.today(),
    );
    final screenWidth = MediaQuery.sizeOf(context).width;

    // NEW: first-time booking CTA (replaces empty day copy when applicable)
    if (showFirstTimeBookingCard) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FirstTimeBookingCard(onBookCoach: onBookCoach),
          if (showProgress)
            SizedBox(
              width: screenWidth - 24,
              child: WeeklyAttendanceChart(summary: weeklyProgress),
            ),
        ],
      );
    }

    if (daySessions.isEmpty && !showProgress) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        child: Text(
          isTodaySelected
              ? 'No sessions scheduled for today'
              : 'No sessions on this day',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      primary: false,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      clipBehavior: Clip.none,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final session in daySessions)
            RepaintBoundary(
              child: _buildSessionCard(
                session,
                showTodayBanner: isTodaySelected,
              ),
            ),
          if (showProgress)
            RepaintBoundary(
              child: SizedBox(
                width: screenWidth - 24,
                child: WeeklyAttendanceChart(summary: weeklyProgress),
              ),
            ),
        ],
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
            padding: const EdgeInsets.symmetric(horizontal: 12),
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
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            primary: false,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
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
        const SizedBox(height: 4),
      ],
    );
  }
}
