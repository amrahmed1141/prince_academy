import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/widgets/shimmer_widgets.dart';
import 'package:prince_academy/features/admin/data/models/session_detail_model.dart';
import 'package:prince_academy/features/admin/presentation/bloc/session_detail_state.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_session_list_tile.dart';
import 'package:prince_academy/features/sessions/presentation/bloc/user_session_detail_bloc.dart';
import 'package:prince_academy/features/sessions/presentation/bloc/user_session_detail_event.dart';

/// Read-only session detail for members (no admin role required).
class UserSessionDetailPage extends StatefulWidget {
  final String bookingId;
  final String coachName;
  final String coachSpecialty;
  final String? sessionTime;
  final String? branchName;

  const UserSessionDetailPage({
    super.key,
    required this.bookingId,
    required this.coachName,
    required this.coachSpecialty,
    this.sessionTime,
    this.branchName,
  });

  @override
  State<UserSessionDetailPage> createState() => _UserSessionDetailPageState();
}

class _UserSessionDetailPageState extends State<UserSessionDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<UserSessionDetailBloc>()
        ..add(UserSessionDetailStarted(widget.bookingId)),
      child: BlocBuilder<UserSessionDetailBloc, SessionDetailState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: EColorConstants.authFieldBackground,
            appBar: AppBar(
              backgroundColor: EColorConstants.authFieldBackground,
              elevation: 0,
              leading: const BackButton(),
              title: Text(
                '${widget.coachName} · ${widget.coachSpecialty}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: EColorConstants.authTextDarkBrown,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            body: _buildBody(context, state),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, SessionDetailState state) {
    if (state is SessionDetailLoading || state is SessionDetailInitial) {
      return const Column(
        children: [
          StatsShimmer(),
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CoachListShimmer(itemCount: 2),
              ),
            ),
          ),
        ],
      );
    }

    if (state is SessionDetailError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Iconsax.warning_2, size: 40),
              const SizedBox(height: 12),
              Text(state.message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context
                      .read<UserSessionDetailBloc>()
                      .add(UserSessionDetailStarted(widget.bookingId));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state is! SessionDetailLoaded) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              _StatCard(label: 'Total', value: '${state.totalSessions}'),
              const SizedBox(width: 10),
              _StatCard(label: 'Done', value: '${state.completedCount}'),
              const SizedBox(width: 10),
              _StatCard(label: 'Left', value: '${state.remainingCount}'),
            ],
          ),
        ),
        Material(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: EColorConstants.primaryColor,
            unselectedLabelColor: EColorConstants.authPlaceholderGray,
            indicatorColor: EColorConstants.primaryColor,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
              fontSize: 13,
            ),
            tabs: [
              Tab(text: 'Completed (${state.completed.length})'),
              Tab(text: 'Upcoming (${state.upcoming.length})'),
              Tab(text: 'Missed (${state.missed.length})'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _SessionList(
                sessions: state.completed,
                emptyMessage: 'No completed sessions yet',
                coachName: widget.coachName,
                sessionTime: widget.sessionTime,
                branchName: widget.branchName,
                type: _SessionListType.completed,
                onRefresh: _refreshDetail,
              ),
              _SessionList(
                sessions: state.upcoming,
                emptyMessage: 'No upcoming sessions',
                coachName: widget.coachName,
                sessionTime: widget.sessionTime,
                branchName: widget.branchName,
                type: _SessionListType.upcoming,
                onRefresh: _refreshDetail,
              ),
              _SessionList(
                sessions: state.missed,
                emptyMessage: 'No missed sessions',
                coachName: widget.coachName,
                sessionTime: widget.sessionTime,
                branchName: widget.branchName,
                type: _SessionListType.missed,
                onRefresh: _refreshDetail,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _refreshDetail() async {
    context
        .read<UserSessionDetailBloc>()
        .add(RefreshUserSessionDetail(widget.bookingId));
    await context.read<UserSessionDetailBloc>().stream.firstWhere(
          (s) => s is SessionDetailLoaded || s is SessionDetailError,
        );
  }
}

enum _SessionListType { completed, upcoming, missed }

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: EColorConstants.authFieldBorder),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: EColorConstants.authTextDarkBrown,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
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

class _SessionList extends StatelessWidget {
  final List<SessionDetail> sessions;
  final String emptyMessage;
  final String coachName;
  final String? sessionTime;
  final String? branchName;
  final _SessionListType type;
  final Future<void> Function() onRefresh;

  const _SessionList({
    required this.sessions,
    required this.emptyMessage,
    required this.coachName,
    required this.sessionTime,
    this.branchName,
    required this.type,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.3,
              child: Center(
                child: Text(
                  emptyMessage,
                  style: const TextStyle(
                    color: EColorConstants.authPlaceholderGray,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: sessions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final session = sessions[index];
          final time = session.sessionTime ?? sessionTime ?? '—';
          final dateTimeLabel =
              '${session.dayName}, ${session.formattedDate} · $time';

          return AdminSessionListTile(
            key: ValueKey(session.sessionDate.toIso8601String()),
            coachName: coachName,
            dateTimeLabel: dateTimeLabel,
            location: session.branchName ?? branchName,
            status: switch (type) {
              _SessionListType.completed => AdminSessionTileStatus.completed,
              _SessionListType.upcoming => AdminSessionTileStatus.upcoming,
              _SessionListType.missed => AdminSessionTileStatus.missed,
            },
            canReAttend: false,
            canUnmark: false,
          );
        },
      ),
    );
  }
}
