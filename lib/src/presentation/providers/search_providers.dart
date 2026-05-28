import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/reddit_client_provider.dart';
import '../../data/auth_providers.dart';
import '../../data/search_repository.dart';
import '../../data/paginated_list_state.dart';
import '../../domain/models/post.dart';
import '../../domain/models/subreddit.dart';
import '../../domain/models/search_user.dart';
import '../../data/cursor_paginated_notifier.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(ref.watch(redditClientProvider));
});

// ── Generic search notifier ───────────────────────────────────────────────────

typedef SearchPageLoader<T> = Future<SearchResultPage<T>> Function(
    String? after);

class SearchNotifier<T> extends CursorPaginatedNotifier<PaginatedListState<T>,
    SearchResultPage<T>> {
  final SearchPageLoader<T> _loader;

  SearchNotifier(this._loader) : super(const PaginatedListState.initial());

  @override
  Future<SearchResultPage<T>> fetchPage({String? after}) => _loader(after);

  @override
  String? extractAfter(SearchResultPage<T> page) => page.after;

  @override
  PaginatedListState<T> buildLoadingState(PaginatedListState<T> current) =>
      current.copyWith(isLoading: true, clearError: true);

  @override
  PaginatedListState<T> buildSuccessState(SearchResultPage<T> page) =>
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
          PaginatedListState<T> current, SearchResultPage<T> page) =>
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
}

// ── Query-based family providers ──────────────────────────────────────────────

final searchPostsProvider = StateNotifierProvider.family<SearchNotifier<Post>,
    PaginatedListState<Post>, String>((ref, query) {
  final repo = ref.watch(searchRepositoryProvider);
  final account = ref.watch(activeAccountProvider);
  return SearchNotifier((after) => repo.searchPosts(query,
      after: after, sessionCookie: account?.sessionCookie));
});

final searchCommunitiesProvider = StateNotifierProvider.family<
    SearchNotifier<Subreddit>,
    PaginatedListState<Subreddit>,
    String>((ref, query) {
  final repo = ref.watch(searchRepositoryProvider);
  final account = ref.watch(activeAccountProvider);
  return SearchNotifier((after) => repo.searchCommunities(query,
      after: after, sessionCookie: account?.sessionCookie));
});

final searchUsersProvider = StateNotifierProvider.family<
    SearchNotifier<SearchUser>,
    PaginatedListState<SearchUser>,
    String>((ref, query) {
  final repo = ref.watch(searchRepositoryProvider);
  final account = ref.watch(activeAccountProvider);
  return SearchNotifier((after) => repo.searchUsers(query,
      after: after, sessionCookie: account?.sessionCookie));
});

final searchCommentsProvider = StateNotifierProvider.family<
    SearchNotifier<Post>, PaginatedListState<Post>, String>((ref, query) {
  final repo = ref.watch(searchRepositoryProvider);
  final account = ref.watch(activeAccountProvider);
  return SearchNotifier((after) => repo.searchComments(query,
      after: after, sessionCookie: account?.sessionCookie));
});
