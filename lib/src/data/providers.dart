import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/reddit_client.dart';
import '../data/account_repository.dart';
import '../data/feed_repository.dart';
import '../data/subreddit_repository.dart';
import '../domain/models/account.dart';
import '../domain/models/session_cookie.dart';
import '../domain/models/feed.dart';
import '../domain/enums/feed_sort.dart';

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

class ActiveAccountNotifier extends StateNotifier<Account?> {
  final AccountRepository _repository;

  ActiveAccountNotifier(this._repository) : super(_repository.loadActive());

  Future<void> setActive(Account account) async {
    await _repository.setActive(account.id);
    state = account;
  }

  Future<void> addAccount(Account account) async {
    await _repository.save(account);
    state = account;
  }

  Future<void> removeAccount(String accountId) async {
    await _repository.remove(accountId);
    if (state?.id == accountId) {
      state = _repository.loadActive();
    }
  }
}

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


