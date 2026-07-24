import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/helpers/subscription_formatters.dart';
import 'package:prince_academy/core/widgets/app_search_bar.dart';
import 'package:prince_academy/features/admin/data/models/active_user_model.dart';
import 'package:prince_academy/features/admin/data/repositories/coach_repository.dart';
import 'package:prince_academy/features/admin/presentation/bloc/members/members_list_cubit.dart';
import 'package:prince_academy/features/admin/presentation/bloc/members/members_list_state.dart';
import 'package:prince_academy/features/admin/presentation/pages/tracking/user_tracking_detail_page.dart';

class AllMembersPage extends StatelessWidget {
  final List<ActiveUser> initialMembers;

  const AllMembersPage({
    super.key,
    this.initialMembers = const [],
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MembersListCubit(
        sl<CoachRepository>(),
        initialMembers: initialMembers,
      )..load(),
      child: const _AllMembersView(),
    );
  }
}

class _AllMembersView extends StatefulWidget {
  const _AllMembersView();

  @override
  State<_AllMembersView> createState() => _AllMembersViewState();
}

class _AllMembersViewState extends State<_AllMembersView> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      context.read<MembersListCubit>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MembersListCubit, MembersListState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: EColorConstants.authFieldBackground,
          appBar: AppBar(
            backgroundColor: EColorConstants.authFieldBackground,
            elevation: 0,
            leading: const BackButton(color: EColorConstants.authTextDarkBrown),
            title: Text(
              'All Members (${state.titleCountLabel})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: EColorConstants.authTextDarkBrown,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          body: Column(
            children: [
              AppSearchBar(
                controller: _searchController,
                hintText: 'Search by name or phone...',
                variant: AppSearchBarVariant.outlined,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                onChanged: context.read<MembersListCubit>().onSearchChanged,
                onClear: () {
                  _searchController.clear();
                  context.read<MembersListCubit>().clearSearch();
                },
              ),
              Expanded(child: _buildBody(context, state)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, MembersListState state) {
    if (state.isLoading && state.members.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: EColorConstants.primaryColor),
      );
    }

    if (state.error != null && state.members.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.read<MembersListCubit>().load(force: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.members.isEmpty) {
      return const Center(
        child: Text(
          'No members match your search.',
          style: TextStyle(
            color: EColorConstants.authPlaceholderGray,
            fontFamily: 'Poppins',
          ),
        ),
      );
    }

    final footerCount = state.isLoadingMore ||
            state.hasMore ||
            state.loadMoreError != null
        ? 1
        : 0;

    return RefreshIndicator(
      color: EColorConstants.primaryColor,
      onRefresh: () => context.read<MembersListCubit>().load(force: true),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: state.members.length + footerCount,
        itemBuilder: (context, index) {
          if (index >= state.members.length) {
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
                          context.read<MembersListCubit>().loadMore(),
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

          final user = state.members[index];
          return _MemberCard(
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
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final ActiveUser user;
  final VoidCallback onTap;

  const _MemberCard({
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
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2E7D32),
                          shape: BoxShape.circle,
                        ),
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
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD32F2F),
                          shape: BoxShape.circle,
                        ),
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
              size: 18,
              color: EColorConstants.authPlaceholderGray,
            ),
          ],
        ),
      ),
    );
  }
}
