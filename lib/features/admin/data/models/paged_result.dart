class PagedResult<T> {
  final List<T> items;
  final bool hasMore;
  final int? totalCount;

  const PagedResult({
    required this.items,
    required this.hasMore,
    this.totalCount,
  });

  factory PagedResult.empty() => const PagedResult(items: [], hasMore: false);

  PagedResult<T> copyWith({
    List<T>? items,
    bool? hasMore,
    int? totalCount,
  }) {
    return PagedResult(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}
