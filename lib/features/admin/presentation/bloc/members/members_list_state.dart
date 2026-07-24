import 'package:equatable/equatable.dart';
import 'package:prince_academy/features/admin/data/models/active_user_model.dart';

class MembersListState extends Equatable {
  final List<ActiveUser> members;
  final String searchQuery;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isRefreshing;
  final bool hasMore;
  final int? totalCount;
  final String? error;
  final String? loadMoreError;

  static const int pageSize = 50;

  const MembersListState({
    this.members = const [],
    this.searchQuery = '',
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.hasMore = false,
    this.totalCount,
    this.error,
    this.loadMoreError,
  });

  String get titleCountLabel {
    if (totalCount != null) return '$totalCount';
    if (hasMore) return '${members.length}+';
    return '${members.length}';
  }

  MembersListState copyWith({
    List<ActiveUser>? members,
    String? searchQuery,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isRefreshing,
    bool? hasMore,
    int? totalCount,
    bool clearTotalCount = false,
    String? error,
    bool clearError = false,
    String? loadMoreError,
    bool clearLoadMoreError = false,
  }) {
    return MembersListState(
      members: members ?? this.members,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      hasMore: hasMore ?? this.hasMore,
      totalCount: clearTotalCount ? null : totalCount ?? this.totalCount,
      error: clearError ? null : error ?? this.error,
      loadMoreError:
          clearLoadMoreError ? null : loadMoreError ?? this.loadMoreError,
    );
  }

  @override
  List<Object?> get props => [
        members,
        searchQuery,
        isLoading,
        isLoadingMore,
        isRefreshing,
        hasMore,
        totalCount,
        error,
        loadMoreError,
      ];
}
