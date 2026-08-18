import 'package:equatable/equatable.dart';
import 'package:prince_academy/features/search/data/models/global_search_models.dart';

enum GlobalSearchStatus { idle, loading, ready, error }

class GlobalSearchState extends Equatable {
  const GlobalSearchState({
    this.query = '',
    this.status = GlobalSearchStatus.idle,
    this.results = GlobalSearchResults.empty,
    this.errorMessage,
  });

  final String query;
  final GlobalSearchStatus status;
  final GlobalSearchResults results;
  final String? errorMessage;

  bool get hasQuery => query.isNotEmpty;
  bool get showEmpty =>
      status == GlobalSearchStatus.ready && hasQuery && results.isEmpty;

  GlobalSearchState copyWith({
    String? query,
    GlobalSearchStatus? status,
    GlobalSearchResults? results,
    String? errorMessage,
    bool clearError = false,
  }) {
    return GlobalSearchState(
      query: query ?? this.query,
      status: status ?? this.status,
      results: results ?? this.results,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [query, status, results, errorMessage];
}
