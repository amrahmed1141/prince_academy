import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/widgets/app_search_bar.dart';
import 'package:prince_academy/core/widgets/scroll_away_search_header.dart';
import 'package:prince_academy/core/widgets/shimmer_widgets.dart';
import 'package:prince_academy/features/admin/data/admin_search_index.dart';
import 'package:prince_academy/features/admin/data/repositories/admin_dashboard_repository.dart';
import 'package:prince_academy/features/admin/data/repositories/coach_repository.dart';
import 'package:prince_academy/features/admin/presentation/bloc/today_attendance/today_attendance_cubit.dart';
import 'package:prince_academy/features/admin/presentation/bloc/today_attendance/today_attendance_state.dart';
import 'package:prince_academy/features/admin/presentation/pages/tracking/user_tracking_detail_page.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_coach_booking_filter_chips.dart';
import 'package:prince_academy/features/admin/presentation/widgets/dashboard/today_attendance_kpi_card.dart';
import 'package:prince_academy/features/admin/presentation/widgets/today_attendance_member_tile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TodayAttendancePage extends StatelessWidget {
  const TodayAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TodayAttendanceCubit(
        dashboardRepository: sl<AdminDashboardRepository>(),
        coachRepository: sl<CoachRepository>(),
        supabase: sl<SupabaseClient>(),
      )..load(),
      child: const _TodayAttendanceView(),
    );
  }
}

class _TodayAttendanceView extends StatefulWidget {
  const _TodayAttendanceView();

  @override
  State<_TodayAttendanceView> createState() => _TodayAttendanceViewState();
}

class _TodayAttendanceViewState extends State<_TodayAttendanceView> {
  final _searchController = TextEditingController();

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification.metrics.pixels >=
        notification.metrics.maxScrollExtent - 240) {
      context.read<TodayAttendanceCubit>().loadMore();
    }
    return false;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openMemberDetail(BuildContext context, TodayAttendanceState state, int index) {
    final member = state.members[index];
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserTrackingDetailPage(
          userId: member.userId,
          initialName: member.memberName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TodayAttendanceCubit, TodayAttendanceState>(
      listenWhen: (prev, next) =>
          prev.actionError != next.actionError && next.actionError != null,
      listener: (context, state) {
        final message = state.actionError;
        if (message == null || message.isEmpty) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
      child: BlocBuilder<TodayAttendanceCubit, TodayAttendanceState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: EColorConstants.authFieldBackground,
            body: NotificationListener<ScrollNotification>(
              onNotification: _onScrollNotification,
              child: NestedScrollView(
                floatHeaderSlivers: true,
                headerSliverBuilder: (context, _) => [
                  ScrollAwaySearchHeader(
                    leading: const BackButton(
                      color: EColorConstants.authTextDarkBrown,
                    ),
                    title: const Text("Today's attendance"),
                    searchBar: AppSearchBar(
                      controller: _searchController,
                      hintText:
                          'Search by member, coach, session, or branch...',
                      hintPhrases: AdminSearchHints.attendance,
                      variant: AppSearchBarVariant.outlined,
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                      onChanged: context
                          .read<TodayAttendanceCubit>()
                          .onSearchChanged,
                      onClear: () {
                        _searchController.clear();
                        context.read<TodayAttendanceCubit>().clearSearch();
                      },
                    ),
                  ),
                ],
                body: _buildScrollBody(context, state),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScrollBody(BuildContext context, TodayAttendanceState state) {
    if (state.isLoading && state.members.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          _KpiHeader(state: state),
          const SizedBox(height: 8),
          const CoachListShimmer(itemCount: 6),
        ],
      );
    }

    if (state.error != null && state.members.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          _KpiHeader(state: state),
          const SizedBox(height: 24),
          Text(state.error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton(
              onPressed: () =>
                  context.read<TodayAttendanceCubit>().load(force: true),
              child: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    final visible = state.visibleMembers;
    final coaches = state.coachOptions;
    final showCoachBar = coaches.isNotEmpty;

    final empty = visible.isEmpty;
    final footerCount = (!empty &&
            (state.isLoadingMore ||
                state.hasMore ||
                state.loadMoreError != null))
        ? 1
        : 0;

    // Header slots: KPI + optional coach chips (+ spacer before list).
    const kpiSlot = 1;
    final coachSlot = showCoachBar ? 1 : 0;
    final emptySlot = empty ? 1 : 0;
    final headerCount = kpiSlot + coachSlot;
    final itemCount = headerCount + (empty ? emptySlot : visible.length) + footerCount;

    return RefreshIndicator(
      color: EColorConstants.primaryColor,
      onRefresh: () => context.read<TodayAttendanceCubit>().refresh(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: _KpiHeader(state: state),
            );
          }

          var cursor = 1;
          if (showCoachBar) {
            if (index == cursor) {
              return _CoachFilterBar(state: state);
            }
            cursor++;
          }

          if (empty) {
            if (index == cursor) {
              return _EmptyMembers(state: state);
            }
            return const SizedBox.shrink();
          }

          final memberIndex = index - headerCount;
          if (memberIndex < visible.length) {
            final member = visible[memberIndex];
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: TodayAttendanceMemberTile(
                member: member,
                isMarking: state.markingBookingIds.contains(member.bookingId),
                onTap: () => _openMemberDetail(context, state, memberIndex),
                onMarkAttended: member.isAttended
                    ? null
                    : () => context
                        .read<TodayAttendanceCubit>()
                        .markAttended(member),
              ),
            );
          }

          if (state.loadMoreError != null) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Column(
                children: [
                  Text(
                    state.loadMoreError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: EColorConstants.authPlaceholderGray,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        context.read<TodayAttendanceCubit>().loadMore(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: EColorConstants.primaryColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _KpiHeader extends StatelessWidget {
  const _KpiHeader({required this.state});

  final TodayAttendanceState state;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: TodayAttendanceKpiCard.heroTag,
      child: Material(
        color: Colors.transparent,
        child: TodayAttendanceKpiCard(
          attended: state.attendedTotal,
          booked: state.bookedTotal,
          fillHeight: false,
        ),
      ),
    );
  }
}

class _EmptyMembers extends StatelessWidget {
  const _EmptyMembers({required this.state});

  final TodayAttendanceState state;

  @override
  Widget build(BuildContext context) {
    final hasSearch = state.searchQuery.trim().isNotEmpty;
    final hasCoachFilter = state.selectedCoachId != null;

    String emptyTitle;
    if (hasSearch) {
      emptyTitle = 'No members match your search.';
    } else if (hasCoachFilter) {
      emptyTitle = 'No members for this coach today.';
    } else {
      emptyTitle = 'No members expected today';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      child: Column(
        children: [
          Icon(
            Iconsax.calendar_remove,
            size: 48,
            color: EColorConstants.authPlaceholderGray.withOpacity(0.8),
          ),
          const SizedBox(height: 12),
          Text(
            emptyTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: EColorConstants.authTextDarkBrown,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          if (!hasSearch && !hasCoachFilter) ...[
            const SizedBox(height: 4),
            const Text(
              'Booked members for today\'s sessions will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: EColorConstants.authPlaceholderGray,
                fontSize: 13,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CoachFilterBar extends StatelessWidget {
  const _CoachFilterBar({required this.state});

  final TodayAttendanceState state;

  @override
  Widget build(BuildContext context) {
    final coaches = state.coachOptions;
    if (coaches.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            CoachBookingFilterChip(
              label: 'All',
              isSelected: state.selectedCoachId == null,
              onTap: () =>
                  context.read<TodayAttendanceCubit>().selectCoach(null),
              isAll: true,
            ),
            ...coaches.map(
              (coach) => CoachBookingFilterChip(
                label: coach.coachName,
                photoUrl: coach.coachPhoto,
                isSelected: state.selectedCoachId == coach.coachId,
                onTap: () => context
                    .read<TodayAttendanceCubit>()
                    .selectCoach(coach.coachId),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
