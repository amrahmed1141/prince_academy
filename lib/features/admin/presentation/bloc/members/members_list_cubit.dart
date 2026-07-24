import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/features/admin/data/models/active_user_model.dart';
import 'package:prince_academy/features/admin/data/repositories/coach_repository.dart';
import 'package:prince_academy/features/admin/presentation/bloc/members/members_list_state.dart';

class MembersListCubit extends Cubit<MembersListState> {
  MembersListCubit(this._repository, {List<ActiveUser> initialMembers = const []})
      : super(
          MembersListState(
            members: initialMembers,
            isLoading: initialMembers.isEmpty,
            hasMore: initialMembers.length >= MembersListState.pageSize,
          ),
        );

  final CoachRepository _repository;
  int _requestId = 0;
  Timer? _searchDebounce;

  Future<void> load({bool force = false}) async {
    final requestId = ++_requestId;
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
        search: state.searchQuery,
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
    load(force: true);
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
