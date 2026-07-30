import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/features/admin/data/models/admin_dashboard_model.dart';
import 'package:prince_academy/features/admin/data/repositories/admin_dashboard_repository.dart';
import 'package:prince_academy/features/admin/presentation/bloc/today_sessions/today_sessions_state.dart';

class TodaySessionsCubit extends Cubit<TodaySessionsState> {
  TodaySessionsCubit(this._repository) : super(_initialState(_repository));

  final AdminDashboardRepository _repository;
  int _requestId = 0;
  Timer? _searchDebounce;

  static TodaySessionsState _initialState(AdminDashboardRepository repository) {
    final cached = _cachedSessions(repository);
    return TodaySessionsState(
      sessions: cached,
      isLoading: cached.isEmpty,
    );
  }

  static List<DashboardTodaySession> _cachedSessions(
    AdminDashboardRepository repository,
  ) {
    final cached = repository.cachedValue?.todaySessionsPreview;
    if (cached == null || cached.isEmpty) return const [];
    return List<DashboardTodaySession>.from(cached);
  }

  Future<void> load({bool force = false}) async {
    final requestId = ++_requestId;
    final cached = _cachedSessions(_repository);
    final hasValidCache = cached.isNotEmpty && _repository.hasValidCache;

    // Second open (and later): serve TTL cache with no network.
    if (!force && hasValidCache) {
      emit(
        state.copyWith(
          sessions: cached,
          isLoading: false,
          isRefreshing: false,
          clearError: true,
        ),
      );
      return;
    }

    final keepList = state.sessions.isNotEmpty || cached.isNotEmpty;
    if (cached.isNotEmpty && state.sessions.isEmpty) {
      emit(
        state.copyWith(
          sessions: cached,
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
      final sessions = await _repository.getTodaySessions(force: force);
      if (requestId != _requestId) return;

      emit(
        state.copyWith(
          sessions: sessions,
          isLoading: false,
          isRefreshing: false,
          clearError: true,
        ),
      );
    } catch (e) {
      if (requestId != _requestId) return;
      emit(
        state.copyWith(
          isLoading: false,
          isRefreshing: false,
          error: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> refresh() => load(force: true);

  void onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      final trimmed = query.trim();
      if (trimmed == state.searchQuery) return;
      emit(state.copyWith(searchQuery: trimmed));
    });
  }

  void clearSearch() {
    _searchDebounce?.cancel();
    if (state.searchQuery.isEmpty) return;
    emit(state.copyWith(searchQuery: ''));
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}
