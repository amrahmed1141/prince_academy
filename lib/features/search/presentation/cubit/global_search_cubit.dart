import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/features/search/data/member_app_search_index.dart';
import 'package:prince_academy/features/search/data/models/global_search_models.dart';
import 'package:prince_academy/features/search/data/repositories/global_search_repository.dart';
import 'package:prince_academy/features/search/presentation/cubit/global_search_state.dart';

class GlobalSearchCubit extends Cubit<GlobalSearchState> {
  GlobalSearchCubit(this._repository) : super(const GlobalSearchState());

  final GlobalSearchRepository _repository;
  Timer? _debounce;
  int _requestId = 0;

  static const _debounceDuration = Duration(milliseconds: 280);

  void search(String rawQuery) {
    final query = rawQuery.trim().toLowerCase();
    if (query == state.query && state.status != GlobalSearchStatus.idle) {
      return;
    }

    _debounce?.cancel();

    if (query.isEmpty) {
      _requestId++;
      emit(
        state.copyWith(
          query: '',
          status: GlobalSearchStatus.idle,
          results: GlobalSearchResults.empty,
          clearError: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        query: query,
        status: GlobalSearchStatus.loading,
        results: GlobalSearchResults(
          destinations: MemberAppSearchIndex.match(query),
        ),
        clearError: true,
      ),
    );

    _debounce = Timer(_debounceDuration, () => _runSearch(query));
  }

  void clear() => search('');

  Future<void> _runSearch(String query) async {
    final id = ++_requestId;
    try {
      final results = await _repository.search(query);
      if (isClosed || id != _requestId) return;
      emit(
        state.copyWith(
          query: query,
          status: GlobalSearchStatus.ready,
          results: results,
          clearError: true,
        ),
      );
    } catch (e) {
      if (isClosed || id != _requestId) return;
      emit(
        state.copyWith(
          status: GlobalSearchStatus.error,
          errorMessage: 'Search failed. Please try again.',
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
