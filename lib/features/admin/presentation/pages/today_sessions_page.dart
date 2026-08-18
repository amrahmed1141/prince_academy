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
import 'package:prince_academy/features/admin/presentation/bloc/today_sessions/today_sessions_cubit.dart';
import 'package:prince_academy/features/admin/presentation/bloc/today_sessions/today_sessions_state.dart';
import 'package:prince_academy/features/admin/presentation/widgets/today_session_card.dart';

class TodaySessionsPage extends StatelessWidget {
  const TodaySessionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TodaySessionsCubit(sl<AdminDashboardRepository>())..load(),
      child: const _TodaySessionsView(),
    );
  }
}

class _TodaySessionsView extends StatefulWidget {
  const _TodaySessionsView();

  @override
  State<_TodaySessionsView> createState() => _TodaySessionsViewState();
}

class _TodaySessionsViewState extends State<_TodaySessionsView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodaySessionsCubit, TodaySessionsState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: EColorConstants.authFieldBackground,
          body: NestedScrollView(
            floatHeaderSlivers: true,
            headerSliverBuilder: (context, _) => [
              ScrollAwaySearchHeader(
                leading: const BackButton(
                  color: EColorConstants.authTextDarkBrown,
                ),
                title: Text("Today's Sessions (${state.sessions.length})"),
                searchBar: AppSearchBar(
                  controller: _searchController,
                  hintText: 'Search by coach, session, or branch...',
                  hintPhrases: AdminSearchHints.sessions,
                  variant: AppSearchBarVariant.outlined,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  onChanged:
                      context.read<TodaySessionsCubit>().onSearchChanged,
                  onClear: () {
                    _searchController.clear();
                    context.read<TodaySessionsCubit>().clearSearch();
                  },
                ),
              ),
            ],
            body: _buildBody(context, state),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, TodaySessionsState state) {
    if (state.isLoading && state.sessions.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: const [
          CoachListShimmer(itemCount: 6),
        ],
      );
    }

    if (state.error != null && state.sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () =>
                    context.read<TodaySessionsCubit>().load(force: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final visible = state.visibleSessions;

    if (visible.isEmpty) {
      return RefreshIndicator(
        color: EColorConstants.primaryColor,
        onRefresh: () => context.read<TodaySessionsCubit>().refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Icon(
              Iconsax.calendar_remove,
              size: 48,
              color: EColorConstants.authPlaceholderGray.withOpacity(0.8),
            ),
            const SizedBox(height: 12),
            Text(
              state.searchQuery.isEmpty
                  ? 'No sessions today'
                  : 'No sessions match your search.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: EColorConstants.authTextDarkBrown,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            if (state.searchQuery.isEmpty) ...[
              const SizedBox(height: 4),
              const Text(
                'Scheduled coach sessions for today will show up here.',
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

    return RefreshIndicator(
      color: EColorConstants.primaryColor,
      onRefresh: () => context.read<TodaySessionsCubit>().refresh(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        itemCount: visible.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          return TodaySessionCard(session: visible[index]);
        },
      ),
    );
  }
}
