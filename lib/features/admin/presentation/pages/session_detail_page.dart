import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/widgets/shimmer_widgets.dart';
import 'package:prince_academy/features/admin/data/models/session_detail_model.dart';
import 'package:prince_academy/features/admin/presentation/bloc/session_detail_bloc.dart';
import 'package:prince_academy/features/admin/presentation/bloc/session_detail_event.dart';
import 'package:prince_academy/features/admin/presentation/bloc/session_detail_state.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_session_list_tile.dart';

class SessionDetailPage extends StatefulWidget {
  final String bookingId;
  final String coachName;
  final String coachSpecialty;
  final String? sessionTime;
  final String? branchName;

  const SessionDetailPage({
    super.key,
    required this.bookingId,
    required this.coachName,
    required this.coachSpecialty,
    this.sessionTime,
    this.branchName,
  });

  @override
  State<SessionDetailPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends State<SessionDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _sessionUpdated = false;

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
      create: (_) => sl<SessionDetailBloc>()
        ..add(LoadSessionDetail(widget.bookingId)),
      child: BlocConsumer<SessionDetailBloc, SessionDetailState>(
        listener: (context, state) {
          if (state is! SessionDetailLoaded || state.reAttendMessage == null) {
            return;
          }

          final message = state.reAttendMessage!;
          if (message == 'success') {
            _sessionUpdated = true;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Session marked as attended'),
                backgroundColor: Color(0xFF2E7D32),
              ),
            );
          } else if (message == 'success_unmark') {
            _sessionUpdated = true;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Attendance removed — session marked as missed'),
                backgroundColor: Color(0xFF1565C0),
              ),
            );
          } else if (message == 'already_marked') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Already marked by another admin'),
                backgroundColor: Colors.orange,
              ),
            );
          } else if (message == 'not_marked') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This session was not marked as attended'),
                backgroundColor: Colors.orange,
              ),
            );
          } else if (message.startsWith('error:')) {
            final text = message
                .replaceFirst('error:', '')
                .replaceFirst('Exception: ', '');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(text),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: EColorConstants.authFieldBackground,
            appBar: AppBar(
              backgroundColor: EColorConstants.authFieldBackground,
              elevation: 0,
              leading: BackButton(
                onPressed: () => Navigator.of(context).pop(_sessionUpdated),
              ),
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
                      .read<SessionDetailBloc>()
                      .add(LoadSessionDetail(widget.bookingId));
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
              _StatCard(
                label: 'Total',
                value: '${state.totalSessions}',
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: 'Done',
                value: '${state.completedCount}',
              ),
              const SizedBox(width: 10),
              _StatCard(
                label: 'Left',
                value: '${state.remainingCount}',
              ),
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
                bookingId: widget.bookingId,
                pendingUnmarkDate: state.pendingUnmarkDate,
              ),
              _SessionList(
                sessions: state.upcoming,
                emptyMessage: 'No upcoming sessions',
                coachName: widget.coachName,
                sessionTime: widget.sessionTime,
                branchName: widget.branchName,
                type: _SessionListType.upcoming,
              ),
              _SessionList(
                sessions: state.missed,
                emptyMessage: 'No missed sessions',
                coachName: widget.coachName,
                sessionTime: widget.sessionTime,
                branchName: widget.branchName,
                type: _SessionListType.missed,
                bookingId: widget.bookingId,
                pendingReAttendDate: state.pendingReAttendDate,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _SessionListType { completed, upcoming, missed }

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({
    required this.label,
    required this.value,
  });

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
  final String? bookingId;
  final DateTime? pendingReAttendDate;
  final DateTime? pendingUnmarkDate;

  const _SessionList({
    required this.sessions,
    required this.emptyMessage,
    required this.coachName,
    required this.sessionTime,
    this.branchName,
    required this.type,
    this.bookingId,
    this.pendingReAttendDate,
    this.pendingUnmarkDate,
  });

  static bool _isSameDay(DateTime a, DateTime b) {
    final al = a.toLocal();
    final bl = b.toLocal();
    return al.year == bl.year && al.month == bl.month && al.day == bl.day;
  }

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(
            color: EColorConstants.authPlaceholderGray,
            fontFamily: 'Poppins',
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final session = sessions[index];
        final isReAttending = pendingReAttendDate != null &&
            _isSameDay(pendingReAttendDate!, session.sessionDate);
        final isUnmarking = pendingUnmarkDate != null &&
            _isSameDay(pendingUnmarkDate!, session.sessionDate);

        return _SessionTile(
          key: ValueKey(session.sessionDate.toIso8601String()),
          session: session,
          coachName: coachName,
          sessionTime: session.sessionTime ?? sessionTime,
          branchName: branchName,
          type: type,
          bookingId: bookingId,
          isReAttending: isReAttending,
          isUnmarking: isUnmarking,
        );
      },
    );
  }
}

class _SessionTile extends StatelessWidget {
  final SessionDetail session;
  final String coachName;
  final String? sessionTime;
  final String? branchName;
  final _SessionListType type;
  final String? bookingId;
  final bool isReAttending;
  final bool isUnmarking;

  const _SessionTile({
    super.key,
    required this.session,
    required this.coachName,
    required this.sessionTime,
    this.branchName,
    required this.type,
    this.bookingId,
    this.isReAttending = false,
    this.isUnmarking = false,
  });

  Future<void> _confirmUnmark(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Attendance'),
        content: const Text(
          'Mark this session as not attended? The user did not come.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted && bookingId != null) {
      context.read<SessionDetailBloc>().add(
            UnmarkSession(
              bookingId: bookingId!,
              sessionDate: session.sessionDate,
            ),
          );
    }
  }

  Future<void> _confirmReAttend(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Re-Attend Session'),
        content: const Text('Mark this session as attended?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted && bookingId != null) {
      context.read<SessionDetailBloc>().add(
            ReAttendSession(
              bookingId: bookingId!,
              sessionDate: session.sessionDate,
            ),
          );
    }
  }

  AdminSessionTileStatus get _tileStatus => switch (type) {
        _SessionListType.completed => AdminSessionTileStatus.completed,
        _SessionListType.upcoming => AdminSessionTileStatus.upcoming,
        _SessionListType.missed => AdminSessionTileStatus.missed,
      };

  @override
  Widget build(BuildContext context) {
    final time = sessionTime ?? '—';
    final dateTimeLabel = '${session.dayName}, ${session.formattedDate} · $time';

    return AdminSessionListTile(
      coachName: coachName,
      dateTimeLabel: dateTimeLabel,
      location: session.branchName ?? branchName,
      status: _tileStatus,
      canReAttend: type == _SessionListType.missed && session.canReAttend,
      canUnmark: type == _SessionListType.completed && session.canUnmark,
      isReAttending: isReAttending,
      isUnmarking: isUnmarking,
      onReAttend: type == _SessionListType.missed && session.canReAttend
          ? () => _confirmReAttend(context)
          : null,
      onUnmark: type == _SessionListType.completed && session.canUnmark
          ? () => _confirmUnmark(context)
          : null,
    );
  }
}
