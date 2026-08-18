import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/core/helpers/remote_error.dart';
import 'package:prince_academy/features/admin/data/models/coach_with_sessions.dart';
import 'package:prince_academy/features/admin/data/repositories/coach_repository.dart';
import 'package:prince_academy/features/home/data/models/coach_session_model.dart';

class AllSchedulesCubit extends Cubit<AllSchedulesState> {
  AllSchedulesCubit(this._repository)
      : super(AllSchedulesState.initial(_repository.cachedAllSessions));

  final CoachRepository _repository;
  StreamSubscription<List<CoachSessionModel>>? _subscription;

  Future<void> load({bool force = false}) async {
    final cached = _repository.cachedAllSessions;
    final hasValidCache =
        cached != null && cached.isNotEmpty && _repository.hasValidAllSessionsCache;

    await _subscription?.cancel();
    _repository.ensureAllSessionsRealtime();
    _subscription = _repository.allSessionsStream.listen(
      (sessions) {
        emit(
          state.copyWith(
            groups: CoachWithSessions.group(sessions),
            isLoading: false,
            isRefreshing: false,
            clearError: true,
          ),
        );
      },
      onError: (Object error) {
        emit(
          state.copyWith(
            isLoading: false,
            isRefreshing: false,
            errorMessage: userFacingRemoteError(error),
          ),
        );
      },
    );

    // Second open (and later): serve TTL cache with no network.
    if (!force && hasValidCache) {
      emit(
        state.copyWith(
          groups: CoachWithSessions.group(cached),
          isLoading: false,
          isRefreshing: false,
          clearError: true,
        ),
      );
      return;
    }

    final keepList = state.groups.isNotEmpty || (cached?.isNotEmpty ?? false);
    if (cached != null && cached.isNotEmpty && state.groups.isEmpty) {
      emit(
        state.copyWith(
          groups: CoachWithSessions.group(cached),
          isLoading: false,
          isRefreshing: true,
          clearError: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          isLoading: !keepList,
          isRefreshing: keepList,
          clearError: true,
        ),
      );
    }

    try {
      final sessions = await _repository.getAllSessionsWithCoach(force: force);
      emit(
        AllSchedulesState(
          groups: CoachWithSessions.group(sessions),
          isLoading: false,
          isRefreshing: false,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          isRefreshing: false,
          errorMessage: userFacingRemoteError(error),
        ),
      );
    }
  }

  Future<void> refresh() => load(force: true);

  Future<void> deleteSchedule(List<String> sessionIds) async {
    try {
      for (final id in sessionIds) {
        await _repository.deleteSession(id);
      }
      await load(force: true);
    } catch (error) {
      emit(state.copyWith(errorMessage: userFacingRemoteError(error)));
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

class AllSchedulesState extends Equatable {
  const AllSchedulesState({
    this.groups = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
  });

  factory AllSchedulesState.initial(List<CoachSessionModel>? cached) {
    final groups = cached == null || cached.isEmpty
        ? const <CoachWithSessions>[]
        : CoachWithSessions.group(cached);
    return AllSchedulesState(
      groups: groups,
      isLoading: groups.isEmpty,
    );
  }

  final List<CoachWithSessions> groups;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;

  List<CoachSessionModel> get flatSessions =>
      groups.expand((g) => g.schedules).toList();

  AllSchedulesState copyWith({
    List<CoachWithSessions>? groups,
    bool? isLoading,
    bool? isRefreshing,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AllSchedulesState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [groups, isLoading, isRefreshing, errorMessage];
}
