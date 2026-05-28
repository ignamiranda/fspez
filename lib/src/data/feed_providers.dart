import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/post.dart';
import 'reddit_client_provider.dart';
import 'auth_providers.dart';
import 'feed_parser.dart';
import 'feed_pagination.dart';
import 'paginated_list_state.dart';
import 'paginated_notifier.dart';

final feedParserProvider = Provider<FeedParser>((ref) => FeedParser());

final feedPageProvider = StateNotifierProvider.family<FeedPageNotifier,
    PaginatedListState<Post>, FeedPageConfig>((ref, config) {
  final client = ref.watch(redditClientProvider);
  final parser = ref.watch(feedParserProvider);
  final account = ref.watch(activeAccountProvider);
  return FeedPageNotifier(
    fetchPage: ({after}) async {
      final feed = await fetchForConfig(account, config, after,
          client: client, parser: parser);
      return PaginatedResult<Post>(
        items: feed.posts,
        after: feed.after,
        hasMore: feed.hasMorePages,
      );
    },
  );
});
