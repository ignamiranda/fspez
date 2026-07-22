import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/feed.dart';
import '../domain/models/post.dart';
import 'reddit_client_provider.dart';
import 'auth_providers.dart';
import 'feed_parser.dart';
import 'feed_pagination.dart';
import 'feed_cache.dart';
import 'paginated_list_state.dart';
import 'paginated_notifier.dart';

final feedParserProvider = Provider<FeedParser>((ref) => FeedParser());

final feedPageProvider = StateNotifierProvider.autoDispose
    .family<FeedPageNotifier, PaginatedListState<Post>, FeedPageConfig>((
  ref,
  config,
) {
  final client = ref.watch(redditClientProvider);
  final parser = ref.watch(feedParserProvider);
  final account = ref.watch(activeAccountProvider);
  final cache = ref.watch(feedCacheProvider);

  final accountId = account?.id ?? 'anon';

  // Try to seed from cache
  final cachedEntry = cache.get(accountId, config);
  Feed? cachedFeed;
  var isCachedStale = false;
  if (cachedEntry != null) {
    try {
      final kind = feedKindForConfig(config);
      cachedFeed = parser.parseFeed(cachedEntry.data, kind, config.sort);
      isCachedStale = cachedEntry.isOlderThan(FeedCache.staleAfter);
    } catch (e) {
      debugPrint('FeedPageProvider cache deserialization failed: $e');
      // Corrupt cache entry — remove silently.
      cache.remove(accountId, config);
    }
  }

  // If we have cached data, seed the notifier with it and trigger a background
  // refresh. This avoids showing a loading spinner on repeat visits. The
  // notifier's autoLoad is set to false so it doesn't double-fetch — cached
  // content renders immediately; refresh() handles the network update.
  final notifier = FeedPageNotifier(
    fetchPage: ({after}) async {
      final feed = await fetchForConfig(
        account,
        config,
        after,
        client: client,
        parser: parser,
        onRawResponse:
            after == null ? (data) => cache.set(accountId, config, data) : null,
      );
      return PaginatedResult<Post>(
        items: feed.posts,
        after: feed.after,
        hasMore: feed.hasMorePages,
      );
    },
    autoLoad: cachedFeed == null,
  );

  if (cachedFeed != null) {
    notifier.seedFromCache(cachedFeed, isStale: isCachedStale);
    Future.microtask(() => notifier.refresh());
  }

  return notifier;
});
