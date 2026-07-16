import '../domain/repositories/i_feed_repository.dart';
import '../domain/models/feed.dart';
import '../domain/models/session_cookie.dart';
import '../domain/enums/feed_sort.dart';
import 'reddit_client.dart';
import 'feed_parser.dart';

/// Repository that fetches Reddit feed data.
///
/// Implements [IFeedRepository] by building Reddit API paths and query
/// parameters from [FeedPageKind] and [FeedSort], then delegating to
/// [RedditClient] and [FeedParser] for transport and deserialization.
class FeedRepository implements IFeedRepository {
  final RedditClient _client;
  final FeedParser _parser;

  FeedRepository(this._client, {FeedParser? parser})
      : _parser = parser ?? FeedParser();

  @override
  Future<Feed> fetchFeed({
    required FeedPageKind kind,
    FeedSort sort = FeedSort.hot,
    String? identifier,
    String? after,
    SessionCookie? sessionCookie,
  }) async {
    final path = _buildPath(kind, sort, identifier);
    final queryOverrides = _buildQueryOverrides(kind, identifier);
    final feedKind = _feedKindForKind(kind);

    final params = <String, String>{
      'sort': sort.label,
      if (after != null) 'after': after,
      'limit': '25',
      'sr_detail': 'true',
      if (queryOverrides != null) ...queryOverrides,
    };

    final data =
        await _client.get(path, queryParams: params, sessionCookie: sessionCookie);
    return _parser.parseFeed(data, feedKind, sort);
  }

  /// Builds the Reddit API path for a given feed kind/sort/identifier.
  String _buildPath(FeedPageKind kind, FeedSort sort, String? identifier) {
    return switch (kind) {
      FeedPageKind.home => _pathForSort(sort),
      FeedPageKind.popular => '/r/popular',
      FeedPageKind.popularAll => _popularPathForSort(sort),
      FeedPageKind.saved => '/user/$identifier/saved',
      FeedPageKind.hidden => '/user/$identifier/hidden',
      FeedPageKind.search => '/search',
      FeedPageKind.subreddit => '/r/$identifier',
      FeedPageKind.user => '/user/$identifier/submitted',
    };
  }

  /// Builds query parameter overrides for special feed kinds (e.g., search).
  Map<String, String>? _buildQueryOverrides(
    FeedPageKind kind,
    String? identifier,
  ) {
    return switch (kind) {
      FeedPageKind.search => {
          'q': identifier!,
          'restrict_sr': 'off',
          'sort': 'relevance',
        },
      _ => null,
    };
  }

  /// Maps [FeedPageKind] to the [FeedKind] used by [FeedParser.parseFeed].
  FeedKind _feedKindForKind(FeedPageKind kind) {
    return switch (kind) {
      FeedPageKind.home => FeedKind.home,
      FeedPageKind.popular => FeedKind.popular,
      FeedPageKind.popularAll => FeedKind.popular,
      FeedPageKind.saved => FeedKind.saved,
      FeedPageKind.hidden => FeedKind.saved,
      FeedPageKind.search => FeedKind.popular,
      FeedPageKind.subreddit => FeedKind.home,
      FeedPageKind.user => FeedKind.user,
    };
  }
}

String _pathForSort(FeedSort sort) {
  return switch (sort) {
    FeedSort.best => '/best',
    FeedSort.hot => '/hot',
    FeedSort.new_ => '/new',
    FeedSort.top => '/top',
    FeedSort.rising => '/rising',
    FeedSort.controversial => '/controversial',
  };
}

String _popularPathForSort(FeedSort sort) {
  return switch (sort) {
    FeedSort.hot => '/r/popular/hot',
    FeedSort.new_ => '/r/popular/new',
    FeedSort.top => '/r/popular/top',
    FeedSort.rising => '/r/popular/rising',
    FeedSort.controversial => '/r/popular/controversial',
    FeedSort.best => '/r/popular/hot',
  };
}
