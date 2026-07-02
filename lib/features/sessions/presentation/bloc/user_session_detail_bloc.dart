import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/features/admin/data/models/session_detail_model.dart';
import 'package:prince_academy/features/admin/presentation/bloc/session_detail_state.dart';
import 'package:prince_academy/features/sessions/data/repositories/sessions_repository.dart';
import 'package:prince_academy/features/sessions/presentation/bloc/user_session_detail_event.dart';

/// User-facing session detail — no admin gate on data loading.
class UserSessionDetailBloc
    extends Bloc<UserSessionDetailEvent, SessionDetailState> {
  final SessionsRepository repository;
  StreamSubscription<List<SessionDetail>>? _subscription;
  String? _bookingId;

  UserSessionDetailBloc({required this.repository})
      : super(const SessionDetailInitial()) {
    on<UserSessionDetailStarted>(_onStarted);
    on<RefreshUserSessionDetail>(_onRefresh);
    on<UserSessionDetailDataUpdated>(_onDataUpdated);
    on<UserSessionDetailDataFailed>(_onDataFailed);
  }

  Future<void> _onStarted(
    UserSessionDetailStarted event,
    Emitter<SessionDetailState> emit,
  ) async {
    _bookingId = event.bookingId;

    await _subscription?.cancel();
    _subscription = repository.watchBookingSessions(event.bookingId).listen(
      (sessions) => add(UserSessionDetailDataUpdated(sessions)),
      onError: (Object error) {
        add(UserSessionDetailDataFailed(error.toString()));
      },
    );

    final cached = repository.getCachedBookingSessions(event.bookingId);
    if (cached != null) {
      emit(_buildLoaded(event.bookingId, cached));
      unawaited(
        repository
            .refreshBookingSessions(event.bookingId, force: true)
            .catchError((_) => cached),
      );
    } else {
      emit(const SessionDetailLoading());
      try {
        await repository.refreshBookingSessions(event.bookingId, force: true);
      } catch (e) {
        emit(SessionDetailError('Failed to load sessions: $e'));
      }
    }
  }

  Future<void> _onRefresh(
    RefreshUserSessionDetail event,
    Emitter<SessionDetailState> emit,
  ) async {
    try {
      await repository.refreshBookingSessions(event.bookingId, force: true);
    } catch (e) {
      if (state is! SessionDetailLoaded) {
        emit(SessionDetailError('Failed to load sessions: $e'));
      }
    }
  }

  void _onDataUpdated(
    UserSessionDetailDataUpdated event,
    Emitter<SessionDetailState> emit,
  ) {
    final bookingId = _bookingId;
    if (bookingId == null) return;
    emit(_buildLoaded(bookingId, event.sessions));
  }

  void _onDataFailed(
    UserSessionDetailDataFailed event,
    Emitter<SessionDetailState> emit,
  ) {
    if (state is SessionDetailLoaded) return;
    emit(SessionDetailError(event.message.replaceFirst('Exception: ', '')));
  }

  SessionDetailLoaded _buildLoaded(
    String bookingId,
    List<SessionDetail> sessions,
  ) {
    final partitioned = _partitionSessions(sessions);

    return SessionDetailLoaded(
      bookingId: bookingId,
      completed: partitioned.completed,
      upcoming: partitioned.upcoming,
      missed: partitioned.missed,
      totalSessions: sessions.length,
      completedCount: partitioned.completed.length,
      remainingCount: sessions.length - partitioned.completed.length,
    );
  }

  _PartitionedSessions _partitionSessions(List<SessionDetail> sessions) {
    final completed = <SessionDetail>[];
    final upcoming = <SessionDetail>[];
    final missed = <SessionDetail>[];

    for (final session in sessions) {
      final status = session.status.toLowerCase();

      if (session.isAttended || status == 'completed') {
        completed.add(session);
      } else if (status == 'missed') {
        missed.add(session);
      } else {
        upcoming.add(session);
      }
    }

    int compare(SessionDetail a, SessionDetail b) =>
        a.sessionDate.compareTo(b.sessionDate);

    completed.sort(compare);
    upcoming.sort(compare);
    missed.sort(compare);

    return _PartitionedSessions(
      completed: completed,
      upcoming: upcoming,
      missed: missed,
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

class _PartitionedSessions {
  final List<SessionDetail> completed;
  final List<SessionDetail> upcoming;
  final List<SessionDetail> missed;

  const _PartitionedSessions({
    required this.completed,
    required this.upcoming,
    required this.missed,
  });
}
