import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/core/constants/app_colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/theme/app_gradients.dart';
import 'package:prince_academy/features/sessions/presentation/pages/user_session_detail_page.dart';
import 'package:prince_academy/features/booking/data/models/booking_history_model.dart';
import 'package:prince_academy/features/sessions/data/models/coach_summary_model.dart';
import 'package:prince_academy/features/sessions/data/models/session_model.dart';
import 'package:prince_academy/features/sessions/presentation/bloc/sessions_bloc.dart';
import 'package:prince_academy/features/sessions/presentation/bloc/sessions_event.dart';
import 'package:prince_academy/features/sessions/presentation/bloc/sessions_state.dart';
import 'package:prince_academy/features/sessions/domain/weekly_progress_calculator.dart';
import 'package:prince_academy/features/sessions/domain/weekly_progress_summary.dart';
import 'package:prince_academy/features/sessions/presentation/widgets/booking_session_card.dart';
import 'package:prince_academy/features/sessions/presentation/widgets/coach_chip_list.dart';
import 'package:prince_academy/features/sessions/presentation/widgets/weekly_attendance_chart.dart';

class SessionsPage extends StatelessWidget {
  const SessionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SessionsBloc>(
      create: (_) => sl<SessionsBloc>()..add(SessionsStarted()),
      child: const SessionsView(),
    );
  }
}

class SessionsView extends StatelessWidget {
  const SessionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppGradients.sessionsScreenDecoration(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: BlocBuilder<SessionsBloc, SessionsState>(
            buildWhen: (previous, current) =>
                current is SessionsInitial ||
                current is SessionsLoading ||
                current is SessionsError ||
                current is SessionsLoaded,
            builder: (context, state) {
              if (state is SessionsInitial || state is SessionsLoading) {
                return const _LoadingSkeleton();
              }

              if (state is SessionsError) {
                return _ErrorView(
                  message: state.message,
                  onRetry: () =>
                      context.read<SessionsBloc>().add(SessionsStarted()),
                );
              }

              if (state is SessionsLoaded) {
                // UPDATED: empty state checks bookings instead of session tabs
                if (state.coaches.isEmpty && state.bookings.isEmpty) {
                  return const _EmptySessionsPage();
                }

                return _SessionsLoadedBody(
                  key: ValueKey(
                    '${state.coaches.length}_${state.selectedCoach?.coachId}_${state.bookings.length}',
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}

// UPDATED: simplified body — coach chips + vertical booking list (no tabs/progress)
class _SessionsLoadedBody extends StatelessWidget {
  const _SessionsLoadedBody({super.key});

  Future<void> _openSessionDetail(
    BuildContext context,
    BookingHistoryModel booking,
  ) async {
    await Navigator.of(context).push<void>(
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

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<SessionsBloc>().add(const RefreshSessions());
        await context.read<SessionsBloc>().stream.firstWhere(
              (s) =>
                  (s is SessionsLoaded && !s.isLoading) || s is SessionsError,
            );
      },
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          const SliverToBoxAdapter(child: _SessionsPageHeader()),
          BlocSelector<SessionsBloc, SessionsState, WeeklyProgressSummary>(
            selector: (state) => state is SessionsLoaded
                ? state.weeklyProgress
                : WeeklyProgressSummary.empty,
            builder: (context, weeklyProgress) {
              if (weeklyProgress.days.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverToBoxAdapter(
                child: WeeklyAttendanceChart(summary: weeklyProgress),
              );
            },
          ),
          // UPDATED: coach filter chips kept unchanged
          BlocSelector<SessionsBloc, SessionsState, bool>(
            selector: (state) =>
                state is SessionsLoaded && state.showCoachFilter,
            builder: (context, showFilter) {
              if (!showFilter) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverToBoxAdapter(
                child:
                    BlocSelector<SessionsBloc, SessionsState, _CoachFilterData>(
                  selector: (state) {
                    if (state is! SessionsLoaded) {
                      return const _CoachFilterData.empty();
                    }
                    return _CoachFilterData(
                      coaches: state.coaches,
                      selectedCoach: state.selectedCoach,
                    );
                  },
                  builder: (context, data) {
                    return CoachChipList(
                      coaches: data.coaches,
                      selectedCoach: data.selectedCoach,
                      onSelect: (coachId) {
                        context.read<SessionsBloc>().add(SelectCoach(coachId));
                      },
                    );
                  },
                ),
              );
            },
          ),
          // UPDATED: vertical ListView of booked sessions (one card per booking)
          BlocSelector<SessionsBloc, SessionsState, _BookingListData>(
            selector: (state) {
              if (state is! SessionsLoaded) {
                return const _BookingListData.empty();
              }
              return _BookingListData(
                bookings: state.bookings,
                allSessions: state.allSessions,
              );
            },
            builder: (context, data) {
              final bookings = data.bookings;
              if (bookings.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyView(
                    message: 'No active bookings yet',
                    icon: Icons.event_busy_outlined,
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.only(top: 4, bottom: 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final booking = bookings[index];
                      final displayStatus =
                          WeeklyProgressCalculator.resolveDisplayStatus(
                        booking,
                      );
                      final todaySession =
                          WeeklyProgressCalculator.todaySessionForBooking(
                        booking,
                        data.allSessions,
                      );
                      return RepaintBoundary(
                        child: BookingSessionCard(
                          key: ValueKey(booking.bookingId),
                          booking: booking,
                          displayStatus: displayStatus,
                          todaySession: todaySession,
                          onTap: () => _openSessionDetail(context, booking),
                        ),
                      );
                    },
                    childCount: bookings.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SessionsPageHeader extends StatelessWidget {
  const _SessionsPageHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'My Sessions',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _EmptySessionsPage extends StatelessWidget {
  const _EmptySessionsPage();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SessionsPageHeader(),
        Expanded(
          child: _EmptyView(
            message: 'No active sessions',
            icon: Icons.event_busy_outlined,
          ),
        ),
      ],
    );
  }
}

class _CoachFilterData {
  final List<CoachSummary> coaches;
  final CoachSummary? selectedCoach;

  const _CoachFilterData({
    required this.coaches,
    required this.selectedCoach,
  });

  const _CoachFilterData.empty()
      : coaches = const [],
        selectedCoach = null;
}

class _BookingListData {
  final List<BookingHistoryModel> bookings;
  final List<Session> allSessions;

  const _BookingListData({
    required this.bookings,
    required this.allSessions,
  });

  const _BookingListData.empty()
      : bookings = const [],
        allSessions = const [];
}

// UPDATED: skeleton matches booking-card list layout
class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 28,
            width: 160,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: List.generate(
              4,
              (index) => Container(
                width: 56,
                height: 56,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            3,
            (index) => Container(
              height: 150,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String message;
  final IconData icon;

  const _EmptyView({
    required this.message,
    this.icon = Icons.calendar_today_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Failed to load sessions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
