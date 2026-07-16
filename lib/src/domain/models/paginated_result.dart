/// Result of fetching a single page from a paginated API.
///
/// Carries the page items, the cursor for the next page, and whether more
/// pages exist.
class PaginatedResult<T> {
  final List<T> items;
  final String? after;
  final bool hasMore;

  const PaginatedResult({
    required this.items,
    this.after,
    this.hasMore = false,
  });
}
