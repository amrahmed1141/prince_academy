import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/core/helpers/remote_error.dart';
import 'package:prince_academy/features/admin/data/models/coach_user_stats_model.dart';
import 'package:prince_academy/features/admin/data/repositories/coach_repository.dart';

class AllCoachesCubit extends Cubit<AllCoachesState> {
  AllCoachesCubit(this._repository, {List<CoachUserStats> initialCoaches = const []})
      : super(
          AllCoachesState.initial(
            _repository.cachedCoachUserStats ?? initialCoaches,
          ),
        );

  final CoachRepository _repository;
  StreamSubscription<List<CoachUserStats>>? _subscription;

  Future<void> load({bool force = false}) async {
    final cached = _repository.cachedCoachUserStats;
    final hasValidCache =
        cached != null && cached.isNotEmpty && _repository.hasValidCoachUserStatsCache;

    await _subscription?.cancel();
    _repository.ensureCoachUserStatsRealtime();
    _subscription = _repository.coachUserStatsStream.listen(
      (coaches) {
        emit(
          state.copyWith(
            coaches: coaches,
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
          coaches: List.of(cached),
          isLoading: false,
          isRefreshing: false,
          clearError: true,
        ),
      );
      return;
    }

    final keepList = state.coaches.isNotEmpty || (cached?.isNotEmpty ?? false);
    if (cached != null && cached.isNotEmpty && state.coaches.isEmpty) {
      emit(
        state.copyWith(
          coaches: List.of(cached),
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
      final coaches = await _repository.getCoachUserStats(force: force);
      emit(
        AllCoachesState(
          coaches: coaches,
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

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

class AllCoachesState extends Equatable {
  const AllCoachesState({
    this.coaches = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
  });

  factory AllCoachesState.initial(List<CoachUserStats>? cached) {
    final coaches = cached == null || cached.isEmpty
        ? const <CoachUserStats>[]
        : List<CoachUserStats>.from(cached);
    return AllCoachesState(
      coaches: coaches,
      isLoading: coaches.isEmpty,
    );
  }

  final List<CoachUserStats> coaches;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;

  AllCoachesState copyWith({
    List<CoachUserStats>? coaches,
    bool? isLoading,
    bool? isRefreshing,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AllCoachesState(
      coaches: coaches ?? this.coaches,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [coaches, isLoading, isRefreshing, errorMessage];
}
