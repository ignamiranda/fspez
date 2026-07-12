import 'package:equatable/equatable.dart';

/// Generic state for any cursor-paginated list.
///
/// Covers the common fields needed by feed screens, search results, inbox,
/// profiles, and any other paginated list: items, loading flags, error, hasMore.
///
/// Use with [CursorPaginatedNotifier] (or directly) — see search_providers.dart
/// for a migration example.
class PaginatedListState<T> with Equatable {
  final List<T> items;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final bool isStale;

  const PaginatedListState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = false,
    this.isStale = false,
  });

  /// Convenience constructor for the initial-loading state.
  const PaginatedListState.initial()
      : items = const [],
        isLoading = true,
        isLoadingMore = false,
        error = null,
        hasMore = false,
        isStale = false;

  PaginatedListState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    bool? isStale,
    bool clearError = false,
  }) {
    return PaginatedListState<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      hasMore: hasMore ?? this.hasMore,
      isStale: isStale ?? this.isStale,
    );
  }

  /// Returns a new state with [predicate]-matched item removed.
  PaginatedListState<T> removeItem(bool Function(T) predicate) {
    return copyWith(items: items.where((e) => !predicate(e)).toList());
  }

  /// Returns a new state with the first [predicate]-matched item replaced by [replacement].
  PaginatedListState<T> replaceItem(bool Function(T) predicate, T replacement) {
    final index = items.indexWhere(predicate);
    if (index == -1) return this;
    final newItems = [...items];
    newItems[index] = replacement;
    return copyWith(items: newItems);
  }

  @override
  List<Object?> get props =>
      [items, isLoading, isLoadingMore, error, hasMore, isStale];
}
