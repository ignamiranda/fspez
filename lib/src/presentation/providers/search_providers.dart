import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/reddit_client_provider.dart';
import '../../data/auth_providers.dart';
import '../../data/search_repository.dart';
import '../../data/paginated_list_state.dart';
import '../../data/paginated_notifier.dart';
import '../../domain/models/post.dart';
import '../../domain/models/subreddit.dart';
import '../../domain/models/search_user.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(ref.watch(redditClientProvider));
});

// ── Query-based family providers ──────────────────────────────────────────────

final searchPostsProvider = StateNotifierProvider.family<
    PaginatedNotifier<Post>, PaginatedListState<Post>, String>((ref, query) {
  final repo = ref.watch(searchRepositoryProvider);
  final account = ref.watch(activeAccountProvider);
  return PaginatedNotifier<Post>(
    fetchPage: ({after}) => repo.searchPosts(query,
        after: after, sessionCookie: account?.sessionCookie),
  );
});

final searchCommunitiesProvider = StateNotifierProvider.family<
    PaginatedNotifier<Subreddit>,
    PaginatedListState<Subreddit>,
    String>((ref, query) {
  final repo = ref.watch(searchRepositoryProvider);
  final account = ref.watch(activeAccountProvider);
  return PaginatedNotifier<Subreddit>(
    fetchPage: ({after}) => repo.searchCommunities(query,
        after: after, sessionCookie: account?.sessionCookie),
  );
});

final searchUsersProvider = StateNotifierProvider.family<
    PaginatedNotifier<SearchUser>,
    PaginatedListState<SearchUser>,
    String>((ref, query) {
  final repo = ref.watch(searchRepositoryProvider);
  final account = ref.watch(activeAccountProvider);
  return PaginatedNotifier<SearchUser>(
    fetchPage: ({after}) => repo.searchUsers(query,
        after: after, sessionCookie: account?.sessionCookie),
  );
});

final searchCommentsProvider = StateNotifierProvider.family<
    PaginatedNotifier<Post>, PaginatedListState<Post>, String>((ref, query) {
  final repo = ref.watch(searchRepositoryProvider);
  final account = ref.watch(activeAccountProvider);
  return PaginatedNotifier<Post>(
    fetchPage: ({after}) => repo.searchComments(query,
        after: after, sessionCookie: account?.sessionCookie),
  );
});
