import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'reddit_client.dart';
import 'account_repository.dart';
import 'account_notifier.dart';
import 'feed_repository.dart';
import 'subreddit_repository.dart';
import 'comment_repository.dart';
import 'vote_repository.dart';
import 'vote_notifier.dart';
import 'save_repository.dart';
import 'save_notifier.dart';
import '../domain/models/account.dart';
import '../domain/models/feed.dart';
import '../domain/models/subreddit.dart';
import '../domain/enums/feed_sort.dart';
import '../domain/enums/vote_direction.dart';

final redditClientProvider = Provider<RedditClient>((ref) {
  final client = RedditClient();
  ref.onDispose(() => client.dispose());
  return client;
});

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main');
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(ref.watch(sharedPrefsProvider));
});

final accountsProvider = Provider<List<Account>>((ref) {
  return ref.watch(accountRepositoryProvider).loadAll();
});

final activeAccountProvider =
    StateNotifierProvider<ActiveAccountNotifier, Account?>((ref) {
  return ActiveAccountNotifier(ref.watch(accountRepositoryProvider));
});

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(ref.watch(redditClientProvider));
});

final subredditRepositoryProvider = Provider<SubredditRepository>((ref) {
  return SubredditRepository(ref.watch(redditClientProvider));
});

final homeFeedProvider =
    FutureProvider.family<Feed, ({FeedSort sort, String? after})>(
        (ref, params) async {
  final repo = ref.watch(feedRepositoryProvider);
  final sessionCookie = ref.watch(activeAccountProvider)?.sessionCookie;
  return repo.fetchHome(
      sort: params.sort, after: params.after, sessionCookie: sessionCookie);
});

final popularFeedProvider =
    FutureProvider.family<Feed, String?>((ref, after) async {
  final repo = ref.watch(feedRepositoryProvider);
  final sessionCookie = ref.watch(activeAccountProvider)?.sessionCookie;
  return repo.fetchPopular(after: after, sessionCookie: sessionCookie);
});

final allFeedProvider =
    FutureProvider.family<Feed, ({FeedSort sort, String? after})>(
        (ref, params) async {
  final repo = ref.watch(feedRepositoryProvider);
  final sessionCookie = ref.watch(activeAccountProvider)?.sessionCookie;
  return repo.fetchAll(
      sort: params.sort, after: params.after, sessionCookie: sessionCookie);
});

final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return CommentRepository(ref.watch(redditClientProvider));
});

final postDetailProvider =
    FutureProvider.family<PostDetail, ({String subreddit, String postId})>(
        (ref, params) async {
  final repo = ref.watch(commentRepositoryProvider);
  final sessionCookie = ref.watch(activeAccountProvider)?.sessionCookie;
  return repo.fetchComments(params.subreddit, params.postId,
      sessionCookie: sessionCookie);
});

final subredditFeedProvider =
    FutureProvider.family<Feed, ({String subredditName, FeedSort sort, String? after})>(
        (ref, params) async {
  final repo = ref.watch(feedRepositoryProvider);
  final sessionCookie = ref.watch(activeAccountProvider)?.sessionCookie;
  return repo.fetchSubreddit(params.subredditName,
      sort: params.sort, after: params.after, sessionCookie: sessionCookie);
});

final subredditInfoProvider =
    FutureProvider.family<Subreddit, String>((ref, name) async {
  final repo = ref.watch(subredditRepositoryProvider);
  final sessionCookie = ref.watch(activeAccountProvider)?.sessionCookie;
  return repo.fetch(name, sessionCookie: sessionCookie);
});

final savedFeedProvider =
    FutureProvider.family<Feed, String?>((ref, after) async {
  final repo = ref.watch(feedRepositoryProvider);
  final account = ref.watch(activeAccountProvider);
  return repo.fetchSaved(account!.username,
      after: after, sessionCookie: account.sessionCookie);
});

final voteRepositoryProvider = Provider<VoteRepository>((ref) {
  return VoteRepository(ref.watch(redditClientProvider));
});

final voteProvider =
    StateNotifierProvider<VoteNotifier, Map<String, VoteDirection>>((ref) {
  final repo = ref.watch(voteRepositoryProvider);
  final cookie = ref.watch(activeAccountProvider)?.sessionCookie;
  return VoteNotifier(repo, cookie);
});

final saveRepositoryProvider = Provider<SaveRepository>((ref) {
  return SaveRepository(ref.watch(redditClientProvider));
});

final saveProvider =
    StateNotifierProvider<SaveNotifier, Map<String, bool>>((ref) {
  final repo = ref.watch(saveRepositoryProvider);
  final cookie = ref.watch(activeAccountProvider)?.sessionCookie;
  return SaveNotifier(repo, cookie);
});


