import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/enums/comment_sort.dart';
import '../domain/models/subreddit.dart';
import '../domain/models/subreddit_rule.dart';
import 'reddit_client_provider.dart';
import 'auth_providers.dart';
import 'subreddit_repository.dart';
import 'comment_repository.dart';
import 'write_providers.dart';

final subredditRepositoryProvider = Provider<SubredditRepository>((ref) {
  return SubredditRepository(ref.watch(redditClientProvider));
});

final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return CommentRepository(
    ref.watch(redditClientProvider),
    ref.watch(messageClientProvider),
  );
});

final postDetailProvider = FutureProvider.family<PostDetail,
    ({String subreddit, String postId, CommentSort sort})>((ref, params) async {
  final repo = ref.watch(commentRepositoryProvider);
  final sessionCookie = ref.watch(activeAccountProvider)?.sessionCookie;
  return repo.fetchComments(params.subreddit, params.postId,
      sort: params.sort, sessionCookie: sessionCookie);
});

final subredditInfoProvider =
    FutureProvider.family<Subreddit, String>((ref, name) async {
  final repo = ref.watch(subredditRepositoryProvider);
  final sessionCookie = ref.watch(activeAccountProvider)?.sessionCookie;
  return repo.fetch(name, sessionCookie: sessionCookie);
});

final subredditRulesProvider =
    FutureProvider.family<List<SubredditRule>, String>((ref, name) async {
  final repo = ref.watch(subredditRepositoryProvider);
  final sessionCookie = ref.watch(activeAccountProvider)?.sessionCookie;
  return repo.fetchRules(name, sessionCookie: sessionCookie);
});
