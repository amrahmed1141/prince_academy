import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/theme/app_gradients.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/helpers/subscription_formatters.dart';
import 'package:prince_academy/core/widgets/app_search_bar.dart';
import 'package:prince_academy/core/widgets/scroll_away_search_header.dart';
import 'package:prince_academy/core/widgets/shimmer_widgets.dart';
import 'package:prince_academy/features/admin/data/admin_search_index.dart';
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
  const TrackingPage({
    super.key,
    this.showBackButton = false,
  });

  /// When true, shows a back arrow (pushed route, not the Tracking tab).
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TrackingBloc(
        repository: sl<CoachRepository>(),
        branchRepository: sl<BranchRepository>(),
      )..add(const LoadTrackingData()),
      child: TrackingView(showBackButton: showBackButton),
    );
  }
}

class TrackingView extends StatefulWidget {
  const TrackingView({
    super.key,
    this.showBackButton = false,
  });

  final bool showBackButton;

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
    return BlocBuilder<TrackingBloc, TrackingState>(
      builder: (context, state) {
        final isLoaded = state is TrackingLoaded;
        return AppGradients.lightBackground(
      child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: widget.showBackButton && !isLoaded
              ? AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  leading: const BackButton(
                    color: EColorConstants.authTextDarkBrown,
                  ),
                  title: const Text(
                    'Tracking',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: EColorConstants.authTextDarkBrown,
                      fontFamily: 'Poppins',
                    ),
                  ),
                )
              : null,
          body: SafeArea(
            child: _buildBody(context, state),
          ),
        ));
      },
    );
  }

  Widget _buildBody(BuildContext context, TrackingState state) {
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
          ScrollAwaySearchHeader(
            primary: false,
            automaticallyImplyLeading: false,
            leading: widget.showBackButton
                ? const BackButton(
                    color: EColorConstants.authTextDarkBrown,
                  )
                : null,
            toolbarHeight: 52,
            searchExtent: 64,
            title: const Text(
              'Tracking',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: EColorConstants.authTextDarkBrown,
                fontFamily: 'Poppins',
              ),
            ),
            searchBar: AppSearchBar(
              controller: _searchController,
              hintText: 'Search members...',
              hintPhrases: AdminSearchHints.tracking(context),
              variant: AppSearchBarVariant.outlined,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              onChanged: _onSearchChanged,
              onClear: () {
                _searchDebounce?.cancel();
                context.read<TrackingBloc>().add(const SearchUsers(''));
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 4)),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _BranchFilterChip(
                    label: 'All branches',
                    isSelected: state.selectedBranchId == null,
                    onTap: () {
                      context
                          .read<TrackingBloc>()
                          .add(const FilterByBranch(null));
                    },
                  ),
                  ...state.branches.map(
                    (branch) => _BranchFilterChip(
                      label: branch.name,
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
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SectionHeader(
                icon: Iconsax.teacher,
                title: 'Coach overview',
                count: state.displayCoaches.isEmpty
                    ? null
                    : '${state.displayCoaches.length}',
                isBusy: state.isFiltering,
                onViewAll: () async {
                  final coachId = await Navigator.of(context).push<String>(
                    MaterialPageRoute(
                      builder: (_) => AllCoachesPage(
                        initialCoaches: state.displayCoaches,
                      ),
                    ),
                  );
                  if (!context.mounted || coachId == null) return;
                  context.read<TrackingBloc>().add(FilterByCoach(coachId));
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          if (state.displayCoaches.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'No coaches in this branch.',
                  style: TextStyle(
                    fontSize: 13,
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
                  height: 198,
                  child: _CoachOverviewCard(
                    coach: state.displayCoaches.first,
                    isSelected: state.selectedCoachId ==
                        state.displayCoaches.first.coachId,
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
                height: 198,
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
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    icon: Iconsax.people,
                    title: 'All members',
                    count: state.membersCountLabel,
                    isBusy: state.isSearching,
                    onViewAll: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AllMembersPage(
                            initialMembers: state.visibleUsers,
                          ),
                        ),
                      );
                    },
                  ),
                  if (state.selectedCoachName != null ||
                      state.selectedBranchName != null) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (state.selectedCoachName != null)
                          _ActiveFilterChip(
                            icon: Iconsax.teacher,
                            label: state.selectedCoachName!,
                            onClear: () {
                              context
                                  .read<TrackingBloc>()
                                  .add(const FilterByCoach(null));
                            },
                          ),
                        if (state.selectedBranchName != null)
                          _ActiveFilterChip(
                            icon: Iconsax.location,
                            label: state.selectedBranchName!,
                            onClear: () {
                              context
                                  .read<TrackingBloc>()
                                  .add(const FilterByBranch(null));
                            },
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          if (state.filteredUsers.isEmpty)
            SliverToBoxAdapter(
              child: _EmptyMembersCard(
                message: state.users.isEmpty
                    ? 'No members in database yet.'
                    : 'No members match this filter.',
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

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? count;
  final bool isBusy;
  final VoidCallback onViewAll;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.onViewAll,
    this.count,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: EColorConstants.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: EColorConstants.primaryColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: EColorConstants.authTextDarkBrown,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: EColorConstants.authFieldBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: EColorConstants.authFieldBorder),
                  ),
                  child: Text(
                    count!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: EColorConstants.authTextDarkBrown,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
              if (isBusy) ...[
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
        _ViewAllButton(onTap: onViewAll),
      ],
    );
  }
}

class _ViewAllButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ViewAllButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'View all',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: EColorConstants.primaryColor,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(width: 2),
              Icon(
                Iconsax.arrow_right_3,
                size: 14,
                color: EColorConstants.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onClear;

  const _ActiveFilterChip({
    required this.icon,
    required this.label,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
      decoration: BoxDecoration(
        color: EColorConstants.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: EColorConstants.primaryColor.withOpacity(0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: EColorConstants.primaryColor),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: EColorConstants.authTextDarkBrown,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onClear,
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: EColorConstants.primaryColor,
              ),
            ),
          ),
        ],
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected
                  ? EColorConstants.primaryColor
                  : EColorConstants.authCardWhite,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSelected
                    ? EColorConstants.primaryColor
                    : EColorConstants.authFieldBorder,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: EColorConstants.primaryColor.withOpacity(0.22),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : EColorConstants.authTextDarkBrown,
                fontFamily: 'Poppins',
              ),
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
    this.width = 164,
    this.margin = const EdgeInsets.only(right: 12),
  });

  @override
  Widget build(BuildContext context) {
    final memberLabel =
        '${coach.totalSubscribers} member${coach.totalSubscribers == 1 ? '' : 's'}';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        margin: margin,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: isSelected
              ? EColorConstants.primaryColor.withOpacity(0.08)
              : EColorConstants.authCardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? EColorConstants.primaryColor
                : EColorConstants.authFieldBorder,
            width: isSelected ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.07 : 0.04),
              blurRadius: isSelected ? 14 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? EColorConstants.primaryColor
                      : EColorConstants.authFieldBorder,
                  width: 2,
                ),
              ),
              child: CoachAvatar(
                coachName: coach.coachName,
                photoUrl: coach.coachPhoto,
                size: 58,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    coach.coachName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: EColorConstants.authTextDarkBrown,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Iconsax.verify5,
                  size: 14,
                  color: EColorConstants.primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 4),
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
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: EColorConstants.authFieldBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                memberLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: EColorConstants.authTextDarkBrown,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: _StatPill(
                    color: const Color(0xFF2E7D32),
                    background: const Color(0xFFE8F5E9),
                    label: '${coach.activeSubscribers} active',
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _StatPill(
                    color: const Color(0xFFC62828),
                    background: const Color(0xFFFFEBEE),
                    label: '${coach.expiredSubscribers} exp',
                  ),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 104,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? EColorConstants.primaryColor
              : EColorConstants.authCardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? EColorConstants.primaryColor
                : EColorConstants.authFieldBorder,
            width: isSelected ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? EColorConstants.primaryColor.withOpacity(0.24)
                  : Colors.black.withOpacity(0.04),
              blurRadius: isSelected ? 14 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.18)
                    : EColorConstants.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.people,
                size: 22,
                color: isSelected ? Colors.white : EColorConstants.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'All',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.white
                    : EColorConstants.authTextDarkBrown,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'coaches',
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? Colors.white.withOpacity(0.85)
                    : EColorConstants.authPlaceholderGray,
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: EColorConstants.authCardWhite,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: EColorConstants.authFieldBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.035),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      EColorConstants.primaryColor.withOpacity(0.12),
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
                                fontSize: 14,
                                color: EColorConstants.authTextDarkBrown,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          if (user.hasPendingPayment) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF8E1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFF9A825)
                                      .withOpacity(0.35),
                                ),
                              ),
                              child: const Text(
                                'Pending',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFF57F17),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Iconsax.ticket,
                            size: 12,
                            color: EColorConstants.authPlaceholderGray,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${user.totalBookings} booking${user.totalBookings == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: EColorConstants.authPlaceholderGray,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          if (user.phone != null && user.phone!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(
                                color: EColorConstants.authPlaceholderGray,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Iconsax.call,
                              size: 12,
                              color: EColorConstants.authPlaceholderGray,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                user.phone!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: EColorConstants.authTextDarkBrown,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _StatPill(
                            color: const Color(0xFF2E7D32),
                            background: const Color(0xFFE8F5E9),
                            label: '${user.activeBookings} active',
                            compact: true,
                          ),
                          const SizedBox(width: 6),
                          _StatPill(
                            color: const Color(0xFFC62828),
                            background: const Color(0xFFFFEBEE),
                            label: '${user.expiredBookings} expired',
                            compact: true,
                          ),
                          if (user.latestSubscriptionEnd != null) ...[
                            const Spacer(),
                            Text(
                              SubscriptionFormatters.formatDate(
                                user.latestSubscriptionEnd,
                              ),
                              style: const TextStyle(
                                fontSize: 11,
                                color: EColorConstants.authPlaceholderGray,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: EColorConstants.authFieldBackground,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Iconsax.arrow_right_3,
                    size: 14,
                    color: EColorConstants.authPlaceholderGray,
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

class _StatPill extends StatelessWidget {
  final Color color;
  final Color background;
  final String label;
  final bool compact;

  const _StatPill({
    required this.color,
    required this.background,
    required this.label,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 6,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 10 : 10,
                fontWeight: FontWeight.w600,
                color: color,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMembersCard extends StatelessWidget {
  final String message;

  const _EmptyMembersCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: EColorConstants.authCardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EColorConstants.authFieldBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: EColorConstants.authFieldBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.people,
              size: 26,
              color: EColorConstants.authPlaceholderGray,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: EColorConstants.authPlaceholderGray,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
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
