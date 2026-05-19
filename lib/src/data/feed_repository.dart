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
    return _fetchFeed('/best', sort, after, FeedKind.home,
        sessionCookie: sessionCookie);
  }

  Future<Feed> fetchPopular({String? after, SessionCookie? sessionCookie}) {
    return _fetchFeed('/r/popular', FeedSort.hot, after, FeedKind.popular,
        sessionCookie: sessionCookie);
  }

  Future<Feed> fetchAll(
      {FeedSort sort = FeedSort.hot,
      String? after,
      SessionCookie? sessionCookie}) {
    return _fetchFeed('/r/all', sort, after, FeedKind.all_,
        sessionCookie: sessionCookie);
  }

  Future<Feed> fetchSubreddit(
    String subredditName, {
    FeedSort sort = FeedSort.hot,
    String? after,
    SessionCookie? sessionCookie,
  }) async {
    final data = await _client.get('/r/$subredditName',
        queryParams: {
          'sort': sort.name,
          if (after != null) 'after': after,
          'limit': '25',
        },
        sessionCookie: sessionCookie);
    return _parser.parseFeed(data, FeedKind.home, sort);
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
          'sort': sort.name,
          if (after != null) 'after': after,
          'limit': '25',
        },
        sessionCookie: sessionCookie);
    return _parser.parseFeed(data, kind, sort,
        multiredditName: multiredditName);
  }
}


