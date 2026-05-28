import 'cursor_paginated_notifier.dart';
import 'paginated_list_state.dart';

/// Result of fetching a single page from a paginated API.
///
/// Carries the page items, the cursor for the next page, and whether more
/// pages exist. Used as the page type for [PaginatedNotifier].
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

/// Concrete cursor-paginated notifier that uses [PaginatedListState] as state
/// and [PaginatedResult] as the page type.
///
/// Subclasses (or direct instances) only need to provide a [fetchPage] callback
/// that returns a [PaginatedResult]. All state-building boilerplate is handled
/// here, eliminating the need for per-feature state classes like FeedPageState.
class PaginatedNotifier<T>
    extends CursorPaginatedNotifier<PaginatedListState<T>, PaginatedResult<T>> {
  final Future<PaginatedResult<T>> Function({String? after}) _fetchPage;

  PaginatedNotifier({
    required Future<PaginatedResult<T>> Function({String? after}) fetchPage,
    bool autoLoad = true,
  })  : _fetchPage = fetchPage,
        super(const PaginatedListState.initial(), autoLoad: autoLoad);

  @override
  Future<PaginatedResult<T>> fetchPage({String? after}) =>
      _fetchPage(after: after);

  @override
  String? extractAfter(PaginatedResult<T> page) => page.after;

  @override
  PaginatedListState<T> buildLoadingState(PaginatedListState<T> current) =>
      current.copyWith(isLoading: true, clearError: true);

  @override
  PaginatedListState<T> buildSuccessState(PaginatedResult<T> page) =>
      PaginatedListState<T>(
        items: page.items,
        isLoading: false,
        hasMore: page.hasMore,
      );

  @override
  PaginatedListState<T> buildLoadingMoreState(PaginatedListState<T> current) =>
      current.copyWith(isLoadingMore: true);

  @override
  PaginatedListState<T> buildAppendedState(
          PaginatedListState<T> current, PaginatedResult<T> page) =>
      PaginatedListState<T>(
        items: [...current.items, ...page.items],
        isLoading: false,
        hasMore: page.hasMore,
      );

  @override
  PaginatedListState<T> buildErrorState(String error) =>
      PaginatedListState<T>(isLoading: false, error: error);

  @override
  PaginatedListState<T> buildErrorWithState(
          PaginatedListState<T> current, String error) =>
      current.copyWith(isLoadingMore: false, error: error);

  @override
  bool getIsLoadingMore(PaginatedListState<T> state) => state.isLoadingMore;

  @override
  bool getHasMore(PaginatedListState<T> state) => state.hasMore;

  /// Removes the first item matching [predicate] from the current state.
  void removeItem(bool Function(T) predicate) {
    state = state.removeItem(predicate);
  }
}
