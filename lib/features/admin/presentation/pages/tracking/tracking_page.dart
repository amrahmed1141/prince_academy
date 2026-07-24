import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/helpers/subscription_formatters.dart';
import 'package:prince_academy/core/widgets/app_search_bar.dart';
import 'package:prince_academy/core/widgets/shimmer_widgets.dart';
import 'package:prince_academy/features/admin/data/models/active_user_model.dart';
import 'package:prince_academy/features/admin/data/models/coach_user_stats_model.dart';
import 'package:prince_academy/features/admin/data/repositories/branch_repository.dart';
import 'package:prince_academy/features/admin/data/repositories/coach_repository.dart';
import 'package:prince_academy/features/admin/presentation/bloc/tracking/tracking_bloc.dart';
import 'package:prince_academy/features/admin/presentation/bloc/tracking/tracking_event.dart';
import 'package:prince_academy/features/admin/presentation/bloc/tracking/tracking_state.dart';
import 'package:prince_academy/features/admin/presentation/pages/tracking/all_coaches_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/tracking/all_members_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/tracking/user_tracking_detail_page.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';

class TrackingPage extends StatelessWidget {
  const TrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TrackingBloc(
        repository: sl<CoachRepository>(),
        branchRepository: sl<BranchRepository>(),
      )..add(const LoadTrackingData()),
      child: const TrackingView(),
    );
  }
}

class TrackingView extends StatefulWidget {
  const TrackingView({super.key});

  @override
  State<TrackingView> createState() => _TrackingViewState();
}

class _TrackingViewState extends State<TrackingView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      context.read<TrackingBloc>().add(const LoadMoreSubscribers());
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      context.read<TrackingBloc>().add(SearchUsers(value));
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EColorConstants.authFieldBackground,
      body: SafeArea(
        child: BlocBuilder<TrackingBloc, TrackingState>(
          builder: (context, state) {
            if (state is TrackingInitial || state is TrackingLoading) {
              return const TrackingPageShimmer();
            }

            if (state is TrackingError) {
              return _TrackingErrorView(
                message: state.message,
                onRetry: () {
                  context.read<TrackingBloc>().add(const LoadTrackingData());
                },
              );
            }

            if (state is TrackingLoaded) {
              return _buildContent(context, state);
            }

            return const Center(child: Text('Unknown state'));
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, TrackingLoaded state) {
    return RefreshIndicator(
      color: EColorConstants.primaryColor,
      onRefresh: () async {
        context.read<TrackingBloc>().add(const LoadTrackingData(silent: true));
        await context.read<TrackingBloc>().stream.firstWhere(
              (next) =>
                  (next is TrackingLoaded && !next.isRefreshing) ||
                  next is TrackingError,
            );
      },
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text(
                'Tracking',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: EColorConstants.authTextDarkBrown,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: AppSearchBar(
              controller: _searchController,
              hintText: 'Search by name or phone...',
              variant: AppSearchBarVariant.outlined,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              onChanged: _onSearchChanged,
              onClear: () {
                _searchDebounce?.cancel();
                context.read<TrackingBloc>().add(const SearchUsers(''));
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_city_outlined,
                    size: 16,
                    color: EColorConstants.primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _BranchFilterChip(
                            label: 'ALL BRANCHES',
                            isSelected: state.selectedBranchId == null,
                            onTap: () {
                              context
                                  .read<TrackingBloc>()
                                  .add(const FilterByBranch(null));
                            },
                          ),
                          ...state.branches.map(
                            (branch) => _BranchFilterChip(
                              label: branch.name.toUpperCase(),
                              isSelected: state.selectedBranchId == branch.id,
                              onTap: () {
                                context
                                    .read<TrackingBloc>()
                                    .add(FilterByBranch(branch.id));
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(
                    Iconsax.chart_2,
                    size: 18,
                    color: EColorConstants.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            state.displayCoaches.isEmpty
                                ? 'COACH OVERVIEW'
                                : 'COACH OVERVIEW (${state.displayCoaches.length})',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                              color: EColorConstants.authTextDarkBrown,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        if (state.isFiltering) ...[
                          const SizedBox(width: 8),
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _ViewAllButton(
                    onTap: () async {
                      final coachId = await Navigator.of(context).push<String>(
                        MaterialPageRoute(
                          builder: (_) => AllCoachesPage(
                            initialCoaches: state.displayCoaches,
                          ),
                        ),
                      );
                      if (!context.mounted || coachId == null) return;
                      context
                          .read<TrackingBloc>()
                          .add(FilterByCoach(coachId));
                    },
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          if (state.displayCoaches.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'No coaches in this branch.',
                  style: TextStyle(
                    fontSize: 12,
                    color: EColorConstants.authPlaceholderGray,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            )
          else if (state.displayCoaches.length == 1)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  height: 180,
                  child: _CoachOverviewCard(
                    coach: state.displayCoaches.first,
                    isSelected:
                        state.selectedCoachId == state.displayCoaches.first.coachId,
                    width: double.infinity,
                    margin: EdgeInsets.zero,
                    onTap: () {
                      context.read<TrackingBloc>().add(
                            FilterByCoach(state.displayCoaches.first.coachId),
                          );
                    },
                  ),
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: state.displayCoaches.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _AllCoachChip(
                        isSelected: state.selectedCoachId == null,
                        onTap: () {
                          context
                              .read<TrackingBloc>()
                              .add(const FilterByCoach(null));
                        },
                      );
                    }

                    final coach = state.displayCoaches[index - 1];
                    return _CoachOverviewCard(
                      coach: coach,
                      isSelected: state.selectedCoachId == coach.coachId,
                      onTap: () {
                        context
                            .read<TrackingBloc>()
                            .add(FilterByCoach(coach.coachId));
                      },
                    );
                  },
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Iconsax.user,
                        size: 18,
                        color: EColorConstants.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                'ALL MEMBERS (${state.membersCountLabel})',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                  color: EColorConstants.authTextDarkBrown,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                            if (state.isSearching) ...[
                              const SizedBox(width: 8),
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ],
                          ],
                        ),
                      ),
                      _ViewAllButton(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AllMembersPage(
                                initialMembers: state.visibleUsers,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  if (state.selectedCoachName != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Filtered by ${state.selectedCoachName}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: EColorConstants.authPlaceholderGray,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                  if (state.selectedBranchName != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Branch: ${state.selectedBranchName}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: EColorConstants.authPlaceholderGray,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          if (state.filteredUsers.isEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: EColorConstants.authCardWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: EColorConstants.authFieldBorder),
                ),
                child: Column(
                  children: [
                    Icon(
                      Iconsax.people,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.users.isEmpty
                          ? 'No members in database yet.'
                          : 'No members match this filter.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: EColorConstants.authPlaceholderGray,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final visible = state.visibleUsers;
                  if (index >= visible.length) {
                    if (state.loadMoreError != null) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
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
                              onPressed: () {
                                context
                                    .read<TrackingBloc>()
                                    .add(const LoadMoreSubscribers());
                              },
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
                  }

                  final user = visible[index];
                  return _SubscriberCard(
                    user: user,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => UserTrackingDetailPage(
                            userId: user.userId,
                            initialName: user.fullName,
                            phone: user.phone,
                          ),
                        ),
                      );
                    },
                  );
                },
                childCount: state.visibleUsers.length +
                    (state.isLoadingMore ||
                            state.hasMoreSubscribers ||
                            state.loadMoreError != null
                        ? 1
                        : 0),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _ViewAllButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ViewAllButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Text(
          'View All',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: EColorConstants.primaryColor,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}

class _BranchFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BranchFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? EColorConstants.primaryColor.withOpacity(0.12)
                : EColorConstants.authCardWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? EColorConstants.primaryColor
                  : EColorConstants.authFieldBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: isSelected
                  ? EColorConstants.primaryColor
                  : EColorConstants.authTextDarkBrown,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }
}

class _CoachOverviewCard extends StatelessWidget {
  final CoachUserStats coach;
  final bool isSelected;
  final VoidCallback onTap;
  final double width;
  final EdgeInsetsGeometry margin;

  const _CoachOverviewCard({
    required this.coach,
    required this.isSelected,
    required this.onTap,
    this.width = 156,
    this.margin = const EdgeInsets.only(right: 12),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        margin: margin,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? EColorConstants.primaryColor.withOpacity(0.08)
              : EColorConstants.authCardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? EColorConstants.primaryColor
                : EColorConstants.authFieldBorder,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: EColorConstants.authFieldBorder,
                  width: 2,
                ),
              ),
              child: CoachAvatar(
                coachName: coach.coachName,
                photoUrl: coach.coachPhoto,
                size: 60,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    coach.coachName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: EColorConstants.authTextDarkBrown,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Iconsax.verify5,
                  size: 15,
                  color: EColorConstants.primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              coach.coachSpecialty,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: EColorConstants.authPlaceholderGray,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${coach.totalSubscribers} users',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: EColorConstants.authPlaceholderGray,
                fontFamily: 'Poppins',
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatusDot(
                  color: const Color(0xFF2E7D32),
                  label: '${coach.activeSubscribers} active',
                ),
                const SizedBox(width: 8),
                _StatusDot(
                  color: const Color(0xFFD32F2F),
                  label: '${coach.expiredSubscribers} expired',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AllCoachChip extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _AllCoachChip({
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? EColorConstants.primaryColor.withOpacity(0.12)
              : EColorConstants.authCardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? EColorConstants.primaryColor
                : EColorConstants.authFieldBorder,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: EColorConstants.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.people,
                size: 24,
                color: isSelected
                    ? EColorConstants.primaryColor
                    : EColorConstants.authPlaceholderGray,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'All',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? EColorConstants.primaryColor
                    : EColorConstants.authTextDarkBrown,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Coaches',
              style: TextStyle(
                fontSize: 10,
                color: EColorConstants.authPlaceholderGray,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriberCard extends StatelessWidget {
  final ActiveUser user;
  final VoidCallback onTap;

  const _SubscriberCard({
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = user.fullName
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase())
        .take(2)
        .join();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: EColorConstants.authCardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: EColorConstants.authFieldBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: EColorConstants.primaryColor.withOpacity(0.15),
              child: Text(
                initials.isEmpty ? '?' : initials,
                style: const TextStyle(
                  color: EColorConstants.primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: EColorConstants.authTextDarkBrown,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      if (user.hasPendingPayment) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0xFFF9A825).withOpacity(0.35),
                            ),
                          ),
                          child: const Text(
                            'PENDING',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFF9A825),
                              fontFamily: 'Poppins',
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${user.totalBookings} booking${user.totalBookings == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: EColorConstants.authPlaceholderGray,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  if (user.phone != null && user.phone!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Iconsax.call,
                          size: 13,
                          color: EColorConstants.authPlaceholderGray,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user.phone!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: EColorConstants.authTextDarkBrown,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const _StatusDot(
                        color: Color(0xFF2E7D32),
                        label: '',
                      ),
                      Text(
                        ' ${user.activeBookings} active',
                        style: const TextStyle(
                          fontSize: 11,
                          color: EColorConstants.authPlaceholderGray,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(width: 12),
                      const _StatusDot(
                        color: Color(0xFFD32F2F),
                        label: '',
                      ),
                      Text(
                        ' ${user.expiredBookings} expired',
                        style: const TextStyle(
                          fontSize: 11,
                          color: EColorConstants.authPlaceholderGray,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                  if (user.latestSubscriptionEnd != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Latest: ${SubscriptionFormatters.formatDate(user.latestSubscriptionEnd)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: EColorConstants.authPlaceholderGray,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Iconsax.arrow_right_3,
              size: 16,
              color: EColorConstants.authPlaceholderGray,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;
  final String label;

  const _StatusDot({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    String displayLabel = label;
    if (label.contains(' ')) {
      final parts = label.split(' ');
      if (parts.length == 2 && parts[1].length >= 3) {
        displayLabel = '${parts[0]} ${parts[1].substring(0, 3)}';
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        if (displayLabel.isNotEmpty)
          Text(
            displayLabel,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
              fontFamily: 'Poppins',
            ),
          ),
      ],
    );
  }
}

class _TrackingErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _TrackingErrorView({
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
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'Error loading data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: EColorConstants.authPlaceholderGray,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: EColorConstants.primaryColor,
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
