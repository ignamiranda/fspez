import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'reddit_client.dart';
import 'account_repository.dart';
import 'account_notifier.dart';
import 'feed_repository.dart';
import 'feed_pagination.dart';
import 'subreddit_repository.dart';
import 'comment_repository.dart';
import 'vote_repository.dart';
import 'vote_notifier.dart';
import 'save_notifier.dart';
import 'submit_repository.dart';
import 'inbox_repository.dart';
import 'inbox_notifier.dart';
import 'user_repository.dart';
import '../domain/models/account.dart';
import '../domain/models/subreddit.dart';
import '../domain/models/user_profile.dart';
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

final feedPageProvider =
    StateNotifierProvider.family<FeedPageNotifier, FeedPageState, FeedPageConfig>(
        (ref, config) {
  final repo = ref.watch(feedRepositoryProvider);
  final account = ref.watch(activeAccountProvider);
  return FeedPageNotifier(
    fetchPage: ({after}) => fetchForConfig(repo, account, config, after),
  );
});

final subredditRepositoryProvider = Provider<SubredditRepository>((ref) {
  return SubredditRepository(ref.watch(redditClientProvider));
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

final subredditInfoProvider =
    FutureProvider.family<Subreddit, String>((ref, name) async {
  final repo = ref.watch(subredditRepositoryProvider);
  final sessionCookie = ref.watch(activeAccountProvider)?.sessionCookie;
  return repo.fetch(name, sessionCookie: sessionCookie);
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

final submitRepositoryProvider = Provider<SubmitRepository>((ref) {
  return SubmitRepository(ref.watch(redditClientProvider));
});

final saveProvider =
    StateNotifierProvider<SaveNotifier, Map<String, bool>>((ref) {
  final client = ref.watch(redditClientProvider);
  final cookie = ref.watch(activeAccountProvider)?.sessionCookie;
  return SaveNotifier(client, cookie);
});

final inboxRepositoryProvider = Provider<InboxRepository>((ref) {
  return InboxRepository(ref.watch(redditClientProvider));
});

final inboxProvider =
    StateNotifierProvider<InboxNotifier, InboxState>((ref) {
  final repo = ref.watch(inboxRepositoryProvider);
  final account = ref.watch(activeAccountProvider);
  return InboxNotifier(repo, account);
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(redditClientProvider));
});

final userProfileProvider =
    FutureProvider.family<UserProfile, String>((ref, username) async {
  final repo = ref.watch(userRepositoryProvider);
  final sessionCookie = ref.watch(activeAccountProvider)?.sessionCookie;
  return repo.fetchProfile(username, sessionCookie: sessionCookie);
});
