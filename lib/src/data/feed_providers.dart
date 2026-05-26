import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'reddit_client_provider.dart';
import 'auth_providers.dart';
import 'feed_repository.dart';
import 'feed_pagination.dart';

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
