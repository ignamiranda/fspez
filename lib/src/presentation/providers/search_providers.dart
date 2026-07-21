import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/reddit_client_provider.dart';
import '../../data/auth_providers.dart';
import '../../data/search_repository.dart';
import '../../data/paginated_list_state.dart';
import '../../data/paginated_notifier.dart';
import '../../domain/models/post.dart';
import '../../domain/models/search_user.dart';
import '../../domain/models/session_cookie.dart';
import '../../domain/models/subreddit.dart';

typedef SearchRequest = ({String query, String? subreddit});

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(ref.watch(redditClientProvider));
});

typedef _SearchFetch<T> = Future<PaginatedResult<T>> Function(
  SearchRepository repo, {
  String? after,
  SessionCookie? sessionCookie,
});

PaginatedNotifier<T> _createSearchNotifier<T>(
  Ref ref,
  SearchRequest request,
  _SearchFetch<T> fetch,
) {
  final repo = ref.watch(searchRepositoryProvider);
  return PaginatedNotifier<T>(
    fetchPage: ({after}) => fetch(
      repo,
      after: after,
      sessionCookie: ref.read(activeAccountProvider)?.sessionCookie,
    ),
  );
}

final searchPostsProvider = StateNotifierProvider.autoDispose
    .family<PaginatedNotifier<Post>, PaginatedListState<Post>, SearchRequest>((
  ref,
  request,
) {
  return _createSearchNotifier<Post>(
      ref,
      request,
      (
        repo, {
        after,
        sessionCookie,
      }) =>
          repo.searchPosts(
            request.query,
            after: after,
            subreddit: request.subreddit,
            sessionCookie: sessionCookie,
          ));
});

final searchCommunitiesProvider = StateNotifierProvider.autoDispose.family<
    PaginatedNotifier<Subreddit>,
    PaginatedListState<Subreddit>,
    SearchRequest>((ref, request) {
  return _createSearchNotifier<Subreddit>(
      ref,
      request,
      (
        repo, {
        after,
        sessionCookie,
      }) =>
          repo.searchCommunities(
            request.query,
            after: after,
            subreddit: request.subreddit,
            sessionCookie: sessionCookie,
          ));
});

final searchUsersProvider = StateNotifierProvider.autoDispose.family<
    PaginatedNotifier<SearchUser>,
    PaginatedListState<SearchUser>,
    SearchRequest>((ref, request) {
  return _createSearchNotifier<SearchUser>(
      ref,
      request,
      (
        repo, {
        after,
        sessionCookie,
      }) =>
          repo.searchUsers(
            request.query,
            after: after,
            subreddit: request.subreddit,
            sessionCookie: sessionCookie,
          ));
});

final searchCommentsProvider = StateNotifierProvider.autoDispose
    .family<PaginatedNotifier<Post>, PaginatedListState<Post>, SearchRequest>((
  ref,
  request,
) {
  return _createSearchNotifier<Post>(
      ref,
      request,
      (
        repo, {
        after,
        sessionCookie,
      }) =>
          repo.searchComments(
            request.query,
            after: after,
            subreddit: request.subreddit,
            sessionCookie: sessionCookie,
          ));
});
