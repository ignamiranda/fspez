import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'reddit_client_provider.dart';
import 'auth_providers.dart';
import 'feed_parser.dart';
import 'feed_pagination.dart';

final feedParserProvider = Provider<FeedParser>((ref) => FeedParser());

final feedPageProvider =
    StateNotifierProvider.family<FeedPageNotifier, FeedPageState, FeedPageConfig>(
        (ref, config) {
  final client = ref.watch(redditClientProvider);
  final parser = ref.watch(feedParserProvider);
  final account = ref.watch(activeAccountProvider);
  return FeedPageNotifier(
    fetchPage: ({after}) => fetchForConfig(account, config, after,
        client: client, parser: parser),
  );
});
