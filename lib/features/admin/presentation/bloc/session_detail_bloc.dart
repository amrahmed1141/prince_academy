import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/features/admin/data/models/session_detail_model.dart';
import 'package:prince_academy/features/admin/data/repositories/coach_repository.dart';
import 'package:prince_academy/features/admin/presentation/bloc/session_detail_event.dart';
import 'package:prince_academy/features/admin/presentation/bloc/session_detail_state.dart';

class SessionDetailBloc extends Bloc<SessionDetailEvent, SessionDetailState> {
  final CoachRepository repository;

  SessionDetailBloc({required this.repository})
      : super(const SessionDetailInitial()) {
    on<LoadSessionDetail>(_onLoadSessionDetail);
    on<ReAttendSession>(_onReAttendSession);
    on<UnmarkSession>(_onUnmarkSession);
  }

  Future<void> _onLoadSessionDetail(
    LoadSessionDetail event,
    Emitter<SessionDetailState> emit,
  ) async {
    emit(const SessionDetailLoading());

    try {
      final sessions = await repository.getBookingSessions(event.bookingId);
      final partitioned = _partitionSessions(sessions);

      emit(
        SessionDetailLoaded(
          bookingId: event.bookingId,
          completed: partitioned.completed,
          upcoming: partitioned.upcoming,
          missed: partitioned.missed,
          totalSessions: sessions.length,
          completedCount: partitioned.completed.length,
          remainingCount: sessions.length - partitioned.completed.length,
        ),
      );
    } catch (e) {
      emit(SessionDetailError('Failed to load sessions: $e'));
    }
  }

  Future<void> _onReAttendSession(
    ReAttendSession event,
    Emitter<SessionDetailState> emit,
  ) async {
    final current = state;
    if (current is! SessionDetailLoaded) return;

    emit(current.copyWith(isReAttending: true, clearReAttendMessage: true));

    try {
      final success = await repository.reAttendSession(
        event.bookingId,
        event.sessionDate,
      );

      if (!success) {
        emit(
          current.copyWith(
            isReAttending: false,
            reAttendMessage: 'already_marked',
          ),
        );
        return;
      }

      await _emitReloaded(
        emit,
        event.bookingId,
        feedback: 'success',
      );
    } catch (e) {
      emit(
        current.copyWith(
          isReAttending: false,
          reAttendMessage: 'error:${e.toString().replaceFirst('Exception: ', '')}',
        ),
      );
    }
  }

  Future<void> _onUnmarkSession(
    UnmarkSession event,
    Emitter<SessionDetailState> emit,
  ) async {
    final current = state;
    if (current is! SessionDetailLoaded) return;

    emit(current.copyWith(isUnmarking: true, clearReAttendMessage: true));

    try {
      final success = await repository.unmarkSession(
        event.bookingId,
        event.sessionDate,
      );

      if (!success) {
        emit(
          current.copyWith(
            isUnmarking: false,
            reAttendMessage: 'not_marked',
          ),
        );
        return;
      }

      await _emitReloaded(
        emit,
        event.bookingId,
        feedback: 'success_unmark',
      );
    } catch (e) {
      emit(
        current.copyWith(
          isUnmarking: false,
          reAttendMessage: 'error:${e.toString().replaceFirst('Exception: ', '')}',
        ),
      );
    }
  }

  Future<void> _emitReloaded(
    Emitter<SessionDetailState> emit,
    String bookingId, {
    required String feedback,
  }) async {
    final sessions = await repository.getBookingSessions(bookingId);
    final partitioned = _partitionSessions(sessions);

    emit(
      SessionDetailLoaded(
        bookingId: bookingId,
        completed: partitioned.completed,
        upcoming: partitioned.upcoming,
        missed: partitioned.missed,
        totalSessions: sessions.length,
        completedCount: partitioned.completed.length,
        remainingCount: sessions.length - partitioned.completed.length,
        reAttendMessage: feedback,
      ),
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
      } else if (status == 'upcoming' || status == 'today') {
        upcoming.add(session);
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
