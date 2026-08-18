import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/features/admin/data/admin_search_index.dart';
import 'package:prince_academy/features/admin/data/repositories/admin_search_repository.dart';

enum AdminSearchStatus { idle, loading, ready, error }

class AdminSearchState extends Equatable {
  const AdminSearchState({
    this.query = '',
    this.status = AdminSearchStatus.idle,
    this.results = AdminSearchResults.empty,
    this.errorMessage,
  });

  final String query;
  final AdminSearchStatus status;
  final AdminSearchResults results;
  final String? errorMessage;

  bool get hasQuery => query.isNotEmpty;
  bool get showEmpty =>
      status == AdminSearchStatus.ready && hasQuery && results.isEmpty;

  AdminSearchState copyWith({
    String? query,
    AdminSearchStatus? status,
    AdminSearchResults? results,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AdminSearchState(
      query: query ?? this.query,
      status: status ?? this.status,
      results: results ?? this.results,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [query, status, results, errorMessage];
}

class AdminSearchCubit extends Cubit<AdminSearchState> {
  AdminSearchCubit(this._repository) : super(const AdminSearchState());

  final AdminSearchRepository _repository;
  Timer? _debounce;
  int _requestId = 0;

  static const _debounceDuration = Duration(milliseconds: 280);

  void search(String rawQuery) {
    final query = rawQuery.trim().toLowerCase();
    if (query == state.query && state.status != AdminSearchStatus.idle) {
      return;
    }

    _debounce?.cancel();

    if (query.isEmpty) {
      _requestId++;
      emit(const AdminSearchState());
      return;
    }

    emit(
      state.copyWith(
        query: query,
        status: AdminSearchStatus.loading,
        results: AdminSearchResults(
          destinations: AdminAppSearchIndex.match(query),
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
          status: AdminSearchStatus.ready,
          results: results,
          clearError: true,
        ),
      );
    } catch (_) {
      if (isClosed || id != _requestId) return;
      emit(
        state.copyWith(
          status: AdminSearchStatus.error,
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
