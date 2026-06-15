import 'package:flutter_riverpod/flutter_riverpod.dart';
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
/// Provides [loadInitial], [loadMore], and [refresh] pagination logic directly
/// without an abstract base class. Needs a [fetchPage] callback that returns
/// a [PaginatedResult].
class PaginatedNotifier<T> extends StateNotifier<PaginatedListState<T>> {
  /// The fetch callback. Public so subclasses (e.g. [FeedPageNotifier]) can
  /// call it from overridden [loadInitial] implementations.
  final Future<PaginatedResult<T>> Function({String? after}) fetchPage;
  String? after;

  PaginatedNotifier({
    required Future<PaginatedResult<T>> Function({String? after}) fetchPage,
    bool autoLoad = true,
  })  : fetchPage = fetchPage,
        super(const PaginatedListState.initial()) {
    if (autoLoad) {
      Future.microtask(() => loadInitial());
    }
  }

  Future<void> loadInitial() async {
    state = const PaginatedListState(isLoading: true);
    after = null;
    try {
      final page = await fetchPage(after: null);
      after = page.after;
      state = PaginatedListState<T>(
        items: page.items,
        isLoading: false,
        hasMore: page.hasMore,
        isStale: false,
      );
    } catch (e) {
      state = PaginatedListState<T>(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await fetchPage(after: after);
      after = page.after;
      state = PaginatedListState<T>(
        items: [...state.items, ...page.items],
        isLoading: false,
        hasMore: page.hasMore,
        isStale: state.isStale,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<void> refresh() => loadInitial();

  /// Removes the first item matching [predicate] from the current state.
  void removeItem(bool Function(T) predicate) {
    state = state.removeItem(predicate);
  }
}
