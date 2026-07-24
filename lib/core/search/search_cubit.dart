import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Returns `true` when [item] matches the already-normalized (trimmed + lowercased) [query].
typedef SearchMatcher<T> = bool Function(T item, String query);

/// Immutable search/filter snapshot for [SearchCubit].
class SearchState<T> extends Equatable {
  const SearchState({
    required this.query,
    required this.allItems,
    required this.filteredItems,
  });

  factory SearchState.initial({List<T> items = const []}) {
    final copy = List<T>.unmodifiable(items);
    return SearchState<T>(
      query: '',
      allItems: copy,
      filteredItems: copy,
    );
  }

  /// Normalized query (trimmed + lowercased). Empty when cleared.
  final String query;
  final List<T> allItems;
  final List<T> filteredItems;

  bool get hasQuery => query.isNotEmpty;
  bool get isEmptyResult => filteredItems.isEmpty;

  SearchState<T> copyWith({
    String? query,
    List<T>? allItems,
    List<T>? filteredItems,
  }) {
    return SearchState<T>(
      query: query ?? this.query,
      allItems: allItems ?? this.allItems,
      filteredItems: filteredItems ?? this.filteredItems,
    );
  }

  @override
  List<Object?> get props => [query, allItems, filteredItems];
}

/// Reusable client-side search + filtration cubit.
///
/// Owns the source list and applies [matcher] whenever the query or items change.
/// Feature pages provide a typed matcher; UI stays dumb via [AppSearchBar].
class SearchCubit<T> extends Cubit<SearchState<T>> {
  SearchCubit({
    required SearchMatcher<T> matcher,
    List<T> initialItems = const [],
  })  : _matcher = matcher,
        super(SearchState<T>.initial(items: initialItems));

  final SearchMatcher<T> _matcher;

  /// Replace the source list (e.g. after a fetch) while keeping the current query.
  void setItems(List<T> items) {
    final source = List<T>.unmodifiable(items);
    emit(
      state.copyWith(
        allItems: source,
        filteredItems: _filter(source, state.query),
      ),
    );
  }

  /// Update the query and re-filter. Input is normalized internally.
  void search(String rawQuery) {
    final query = rawQuery.trim().toLowerCase();
    if (query == state.query) return;

    emit(
      state.copyWith(
        query: query,
        filteredItems: _filter(state.allItems, query),
      ),
    );
  }

  void clear() {
    if (!state.hasQuery) return;
    emit(
      state.copyWith(
        query: '',
        filteredItems: List<T>.unmodifiable(state.allItems),
      ),
    );
  }

  List<T> _filter(List<T> items, String query) {
    if (query.isEmpty) return List<T>.unmodifiable(items);
    return List<T>.unmodifiable(
      items.where((item) => _matcher(item, query)),
    );
  }
}
