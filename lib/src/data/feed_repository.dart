import '../domain/models/feed.dart';
import '../domain/models/session_cookie.dart';
import '../domain/enums/feed_sort.dart';
import 'reddit_client.dart';
import 'feed_parser.dart';
import 'reddit_award_html_parser.dart';

class FeedRepository {
  final RedditClient _client;
  final FeedParser _parser;

  FeedRepository(this._client, {FeedParser? parser})
      : _parser = parser ?? FeedParser();

  Future<Feed> fetchHome(
      {FeedSort sort = FeedSort.best,
      String? after,
      SessionCookie? sessionCookie}) {
    return _fetchFeed(_pathForSort(sort), sort, after, FeedKind.home,
        sessionCookie: sessionCookie);
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

  Future<Feed> fetchPopular({String? after, SessionCookie? sessionCookie}) {
    return _fetchFeed('/r/popular', FeedSort.hot, after, FeedKind.popular,
        sessionCookie: sessionCookie);
  }

  Future<Feed> fetchPopularAll(
      {FeedSort sort = FeedSort.hot,
      String? after,
      SessionCookie? sessionCookie}) {
    return _fetchFeed(_popularPathForSort(sort), sort, after, FeedKind.popular,
        sessionCookie: sessionCookie);
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

  Future<Feed> fetchSubreddit(
    String subredditName, {
    FeedSort sort = FeedSort.hot,
    String? after,
    SessionCookie? sessionCookie,
  }) async {
    return _fetchFeed(
      '/r/$subredditName',
      sort,
      after,
      FeedKind.home,
      sessionCookie: sessionCookie,
    );
  }

  Future<Feed> search(
    String query, {
    String? after,
    SessionCookie? sessionCookie,
  }) async {
    return _fetchFeed(
      '/search',
      FeedSort.new_,
      after,
      FeedKind.popular,
      extraQueryParams: {
        'q': query,
        'restrict_sr': 'off',
        'sort': 'relevance',
      },
      sessionCookie: sessionCookie,
    );
  }

  Future<Feed> fetchUserPosts(
    String username, {
    FeedSort sort = FeedSort.new_,
    String? after,
    SessionCookie? sessionCookie,
  }) async {
    return _fetchFeed(
      '/user/$username/submitted',
      sort,
      after,
      FeedKind.user,
      sessionCookie: sessionCookie,
    );
  }

  Future<Feed> fetchSaved(
    String username, {
    String? after,
    SessionCookie? sessionCookie,
  }) async {
    return _fetchFeed(
      '/user/$username/saved',
      FeedSort.new_,
      after,
      FeedKind.saved,
      includeSort: false,
      sessionCookie: sessionCookie,
    );
  }

  Future<Feed> fetchHidden(
    String username, {
    String? after,
    SessionCookie? sessionCookie,
  }) async {
    return _fetchFeed(
      '/user/$username/hidden',
      FeedSort.new_,
      after,
      FeedKind.saved,
      includeSort: false,
      sessionCookie: sessionCookie,
    );
  }

  Future<Feed> _fetchFeed(
    String path,
    FeedSort sort,
    String? after,
    FeedKind kind, {
    String? multiredditName,
    Map<String, String>? extraQueryParams,
    bool includeSort = true,
    SessionCookie? sessionCookie,
  }) async {
    final queryParams = {
      if (includeSort) 'sort': sort.label,
      if (after != null) 'after': after,
      'limit': '25',
      'sr_detail': 'true',
      ...?extraQueryParams,
    };
    final data = await _client.get(
      path,
      queryParams: queryParams,
      sessionCookie: sessionCookie,
    );
    final feed = _parser.parseFeed(
      data,
      kind,
      sort,
      multiredditName: multiredditName,
    );

    try {
      final html = await _client.getHtml(
        path,
        queryParams: queryParams,
        sessionCookie: sessionCookie,
      );
      final awardCounts = RedditAwardHtmlParser.parseAwardCounts(html);
      if (awardCounts.isEmpty) return feed;

      return Feed(
        kind: feed.kind,
        sort: feed.sort,
        posts: feed.posts
            .map(
              (post) => post.copyWith(
                awardCount: awardCounts[post.fullname] ?? post.awardCount,
              ),
            )
            .toList(),
        after: feed.after,
        before: feed.before,
        multiredditName: feed.multiredditName,
      );
    } catch (_) {
      return feed;
    }
  }
}
