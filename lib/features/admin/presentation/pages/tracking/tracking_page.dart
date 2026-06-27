import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/helpers/subscription_formatters.dart';
import 'package:prince_academy/features/admin/data/models/active_user_model.dart';
import 'package:prince_academy/features/admin/data/models/coach_user_stats_model.dart';
import 'package:prince_academy/features/admin/data/repositories/branch_repository.dart';
import 'package:prince_academy/features/admin/data/repositories/coach_repository.dart';
import 'package:prince_academy/features/admin/presentation/bloc/tracking/tracking_bloc.dart';
import 'package:prince_academy/features/admin/presentation/bloc/tracking/tracking_event.dart';
import 'package:prince_academy/features/admin/presentation/bloc/tracking/tracking_state.dart';
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

  @override
  void dispose() {
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
              return const Center(
                child: CircularProgressIndicator(
                  color: EColorConstants.primaryColor,
                ),
              );
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
        context.read<TrackingBloc>().add(const LoadTrackingData());
        await context.read<TrackingBloc>().stream.firstWhere(
              (next) => next is TrackingLoaded || next is TrackingError,
            );
      },
      child: CustomScrollView(
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: EColorConstants.authTextDarkBrown,
                ),
                decoration: InputDecoration(
                  hintText: 'Search by name or phone...',
                  hintStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    color: EColorConstants.authPlaceholderGray,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: EColorConstants.authPlaceholderGray,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            context
                                .read<TrackingBloc>()
                                .add(const SearchUsers(''));
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: EColorConstants.authCardWhite,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: EColorConstants.authFieldBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: EColorConstants.authFieldBorder,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: EColorConstants.primaryColor,
                    ),
                  ),
                ),
                onChanged: (value) {
                  context.read<TrackingBloc>().add(SearchUsers(value));
                  setState(() {});
                },
              ),
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
                  Text(
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
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
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
                      Text(
                        'ALL SUBSCRIBERS (${state.filteredUsers.length})',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: EColorConstants.authTextDarkBrown,
                          fontFamily: 'Poppins',
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
                          ? 'No subscribers in database yet.'
                          : 'No subscribers match this filter.',
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
                  final user = state.filteredUsers[index];
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
                childCount: state.filteredUsers.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
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

  const _CoachOverviewCard({
    required this.coach,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 156,
        margin: const EdgeInsets.only(right: 12),
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
                name: coach.coachName,
                photoUrl: coach.coachPhoto,
                radius: 30,
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
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: EColorConstants.authTextDarkBrown,
                      fontFamily: 'Poppins',
                    ),
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
