import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/features/admin/data/models/active_user_model.dart';
import 'package:prince_academy/features/admin/data/repositories/coach_repository.dart';
import 'package:prince_academy/features/admin/presentation/bloc/members/members_list_state.dart';

class MembersListCubit extends Cubit<MembersListState> {
  MembersListCubit(
    this._repository, {
    List<ActiveUser> initialMembers = const [],
  }) : super(_initialState(_repository, initialMembers));

  final CoachRepository _repository;
  int _requestId = 0;
  Timer? _searchDebounce;

  static MembersListState _initialState(
    CoachRepository repository,
    List<ActiveUser> initialMembers,
  ) {
    if (initialMembers.isNotEmpty) {
      return MembersListState(
        members: initialMembers,
        isLoading: false,
        hasMore: initialMembers.length >= MembersListState.pageSize,
      );
    }

    final cached = repository.cachedMembersFirstPage;
    if (cached != null && cached.items.isNotEmpty) {
      return MembersListState(
        members: List<ActiveUser>.from(cached.items),
        isLoading: false,
        hasMore: cached.hasMore,
        totalCount: cached.totalCount,
      );
    }

    return const MembersListState(isLoading: true);
  }

  Future<void> load({bool force = false}) async {
    final requestId = ++_requestId;
    final search = state.searchQuery.trim();
    final isDefaultQuery = search.isEmpty;

    if (!force && isDefaultQuery) {
      final cached = _repository.cachedMembersFirstPage;
      if (cached != null) {
        emit(
          state.copyWith(
            members: _dedupe(cached.items),
            hasMore: cached.hasMore,
            totalCount: cached.totalCount,
            isLoading: false,
            isRefreshing: false,
            clearError: true,
            clearLoadMoreError: true,
          ),
        );
        return;
      }
    }

    final keepList = state.members.isNotEmpty;
    emit(
      state.copyWith(
        isLoading: !keepList,
        isRefreshing: keepList,
        clearError: true,
        clearLoadMoreError: true,
      ),
    );

    try {
      final page = await _repository.getMembers(
        limit: MembersListState.pageSize,
        offset: 0,
        search: search,
        force: force,
      );
      if (requestId != _requestId) return;

      emit(
        state.copyWith(
          members: _dedupe(page.items),
          hasMore: page.hasMore,
          totalCount: page.totalCount,
          isLoading: false,
          isRefreshing: false,
          clearError: true,
          clearLoadMoreError: true,
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

  void onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      final trimmed = query.trim();
      if (trimmed == state.searchQuery) return;
      emit(state.copyWith(searchQuery: trimmed));
      load(force: true);
    });
  }

  void clearSearch() {
    _searchDebounce?.cancel();
    if (state.searchQuery.isEmpty) return;
    emit(state.copyWith(searchQuery: ''));
    load(force: false);
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore ||
        state.isLoading ||
        state.isRefreshing ||
        !state.hasMore) {
      return;
    }

    final requestId = ++_requestId;
    emit(
      state.copyWith(
        isLoadingMore: true,
        clearLoadMoreError: true,
      ),
    );

    try {
      final page = await _repository.getMembers(
        limit: MembersListState.pageSize,
        offset: state.members.length,
        search: state.searchQuery,
        force: true,
      );
      if (requestId != _requestId) return;

      emit(
        state.copyWith(
          members: _dedupe([...state.members, ...page.items]),
          hasMore: page.hasMore,
          totalCount: page.totalCount ?? state.totalCount,
          isLoadingMore: false,
          clearLoadMoreError: true,
        ),
      );
    } catch (e) {
      if (requestId != _requestId) return;
      emit(
        state.copyWith(
          isLoadingMore: false,
          loadMoreError: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  List<ActiveUser> _dedupe(List<ActiveUser> users) {
    final seen = <String>{};
    final result = <ActiveUser>[];
    for (final user in users) {
      if (seen.add(user.userId)) result.add(user);
    }
    return result;
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}
