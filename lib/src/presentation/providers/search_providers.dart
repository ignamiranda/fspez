import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import '../../data/reddit_client_provider.dart';
import '../../data/auth_providers.dart';
import '../../data/search_repository.dart';
import '../../domain/models/post.dart';
import '../../domain/models/subreddit.dart';
import '../../domain/models/search_user.dart';
import '../../data/cursor_paginated_notifier.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(ref.watch(redditClientProvider));
});

// ── Generic search state ──────────────────────────────────────────────────────

class SearchState<T> with EquatableMixin {
  final List<T> items;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;

  const SearchState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = false,
  });

  @override
  List<Object?> get props => [items, isLoading, isLoadingMore, error, hasMore];
}

// ── Generic search notifier ───────────────────────────────────────────────────

typedef SearchPageLoader<T> = Future<SearchResultPage<T>> Function(String? after);

class SearchNotifier<T> extends CursorPaginatedNotifier<SearchState<T>, SearchResultPage<T>> {
  final SearchPageLoader<T> _loader;

  SearchNotifier(this._loader) : super(const SearchState(isLoading: true));

  @override
  Future<SearchResultPage<T>> fetchPage({String? after}) => _loader(after);

  @override
  String? extractAfter(SearchResultPage<T> page) => page.after;

  @override
  SearchState<T> buildLoadingState(SearchState<T> current) =>
      const SearchState(isLoading: true);

  @override
  SearchState<T> buildSuccessState(SearchResultPage<T> page) => SearchState(
        items: page.items,
        isLoading: false,
        hasMore: page.hasMore,
      );

  @override
  SearchState<T> buildLoadingMoreState(SearchState<T> current) => SearchState(
        items: current.items,
        isLoading: false,
        hasMore: current.hasMore,
        isLoadingMore: true,
      );

  @override
  SearchState<T> buildAppendedState(SearchState<T> current, SearchResultPage<T> page) =>
      SearchState(
        items: [...current.items, ...page.items],
        isLoading: false,
        hasMore: page.hasMore,
      );

  @override
  SearchState<T> buildErrorState(String error) =>
      SearchState(isLoading: false, error: error);

  @override
  SearchState<T> buildErrorWithState(SearchState<T> current, String error) =>
      SearchState(
        items: current.items,
        isLoading: false,
        hasMore: current.hasMore,
        error: error,
      );

  @override
  bool getIsLoadingMore(SearchState<T> state) => state.isLoadingMore;

  @override
  bool getHasMore(SearchState<T> state) => state.hasMore;
}

// ── Query-based family providers ──────────────────────────────────────────────

final searchPostsProvider =
    StateNotifierProvider.family<SearchNotifier<Post>, SearchState<Post>, String>(
        (ref, query) {
  final repo = ref.watch(searchRepositoryProvider);
  final account = ref.watch(activeAccountProvider);
  return SearchNotifier((after) => repo.searchPosts(query,
      after: after, sessionCookie: account?.sessionCookie));
});

final searchCommunitiesProvider =
    StateNotifierProvider.family<SearchNotifier<Subreddit>, SearchState<Subreddit>, String>(
        (ref, query) {
  final repo = ref.watch(searchRepositoryProvider);
  final account = ref.watch(activeAccountProvider);
  return SearchNotifier((after) => repo.searchCommunities(query,
      after: after, sessionCookie: account?.sessionCookie));
});

final searchUsersProvider =
    StateNotifierProvider.family<SearchNotifier<SearchUser>, SearchState<SearchUser>, String>(
        (ref, query) {
  final repo = ref.watch(searchRepositoryProvider);
  final account = ref.watch(activeAccountProvider);
  return SearchNotifier((after) => repo.searchUsers(query,
      after: after, sessionCookie: account?.sessionCookie));
});

final searchCommentsProvider =
    StateNotifierProvider.family<SearchNotifier<Post>, SearchState<Post>, String>(
        (ref, query) {
  final repo = ref.watch(searchRepositoryProvider);
  final account = ref.watch(activeAccountProvider);
  return SearchNotifier((after) => repo.searchComments(query,
      after: after, sessionCookie: account?.sessionCookie));
});
