import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/reddit_client_provider.dart';
import '../../data/auth_providers.dart';
import '../../data/search_repository.dart';
import '../../data/paginated_list_state.dart';
import '../../data/paginated_notifier.dart';
import '../../domain/models/post.dart';
import '../../domain/models/subreddit.dart';
import '../../domain/models/search_user.dart';

typedef SearchRequest = ({String query, String? subreddit});

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(ref.watch(redditClientProvider));
});

// ── Query-based family providers ──────────────────────────────────────────────

final searchPostsProvider = StateNotifierProvider.autoDispose.family<
    PaginatedNotifier<Post>, PaginatedListState<Post>, SearchRequest>((
  ref,
  request,
) {
  final repo = ref.watch(searchRepositoryProvider);
  final account = ref.watch(activeAccountProvider);
  return PaginatedNotifier<Post>(
    fetchPage: ({after}) => repo.searchPosts(
      request.query,
      after: after,
      subreddit: request.subreddit,
      sessionCookie: account?.sessionCookie,
    ),
  );
});

final searchCommunitiesProvider = StateNotifierProvider.autoDispose.family<
    PaginatedNotifier<Subreddit>,
    PaginatedListState<Subreddit>,
    SearchRequest>((ref, request) {
  final repo = ref.watch(searchRepositoryProvider);
  final account = ref.watch(activeAccountProvider);
  return PaginatedNotifier<Subreddit>(
    fetchPage: ({after}) => repo.searchCommunities(
      request.query,
      after: after,
      subreddit: request.subreddit,
      sessionCookie: account?.sessionCookie,
    ),
  );
});

final searchUsersProvider = StateNotifierProvider.autoDispose.family<
    PaginatedNotifier<SearchUser>,
    PaginatedListState<SearchUser>,
    SearchRequest>((ref, request) {
  final repo = ref.watch(searchRepositoryProvider);
  final account = ref.watch(activeAccountProvider);
  return PaginatedNotifier<SearchUser>(
    fetchPage: ({after}) => repo.searchUsers(
      request.query,
      after: after,
      subreddit: request.subreddit,
      sessionCookie: account?.sessionCookie,
    ),
  );
});

final searchCommentsProvider = StateNotifierProvider.autoDispose.family<
    PaginatedNotifier<Post>, PaginatedListState<Post>, SearchRequest>((
  ref,
  request,
) {
  final repo = ref.watch(searchRepositoryProvider);
  final account = ref.watch(activeAccountProvider);
  return PaginatedNotifier<Post>(
    fetchPage: ({after}) => repo.searchComments(
      request.query,
      after: after,
      subreddit: request.subreddit,
      sessionCookie: account?.sessionCookie,
    ),
  );
});
