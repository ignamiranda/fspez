import '../domain/models/feed.dart';
import '../domain/models/session_cookie.dart';
import '../domain/enums/feed_sort.dart';
import 'reddit_client.dart';
import 'feed_parser.dart';

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
    final data = await _client.get('/r/$subredditName',
        queryParams: {
          'sort': sort.label,
          if (after != null) 'after': after,
          'limit': '25',
          'sr_detail': 'true',
        },
        sessionCookie: sessionCookie);
    return _parser.parseFeed(data, FeedKind.home, sort);
  }

  Future<Feed> search(
    String query, {
    String? after,
    SessionCookie? sessionCookie,
  }) async {
    final data = await _client.get('/search',
        queryParams: {
          'q': query,
          'restrict_sr': 'off',
          'sort': 'relevance',
          'limit': '25',
          'sr_detail': 'true',
          if (after != null) 'after': after,
        },
        sessionCookie: sessionCookie);
    return _parser.parseFeed(data, FeedKind.popular, FeedSort.new_);
  }

  Future<Feed> fetchUserPosts(
    String username, {
    FeedSort sort = FeedSort.new_,
    String? after,
    SessionCookie? sessionCookie,
  }) async {
    final data = await _client.get('/user/$username/submitted',
        queryParams: {
          'sort': sort.label,
          if (after != null) 'after': after,
          'limit': '25',
          'sr_detail': 'true',
        },
        sessionCookie: sessionCookie);
    return _parser.parseFeed(data, FeedKind.user, sort);
  }

  Future<Feed> fetchSaved(
    String username, {
    String? after,
    SessionCookie? sessionCookie,
  }) async {
    final data = await _client.get('/user/$username/saved',
        queryParams: {
          if (after != null) 'after': after,
          'limit': '25',
          'sr_detail': 'true',
        },
        sessionCookie: sessionCookie);
    return _parser.parseFeed(data, FeedKind.saved, FeedSort.new_);
  }

  Future<Feed> _fetchFeed(
    String path,
    FeedSort sort,
    String? after,
    FeedKind kind, {
    String? multiredditName,
    SessionCookie? sessionCookie,
  }) async {
    final data = await _client.get(path,
        queryParams: {
          'sort': sort.label,
          if (after != null) 'after': after,
          'limit': '25',
          'sr_detail': 'true',
        },
        sessionCookie: sessionCookie);
    return _parser.parseFeed(data, kind, sort,
        multiredditName: multiredditName);
  }
}


