import '../domain/models/post.dart';
import '../domain/models/subreddit.dart';
import '../domain/models/search_user.dart';
import '../domain/models/session_cookie.dart';
import 'html_search_parser.dart';
import 'reddit_client.dart';
import 'paginated_notifier.dart';

class SearchRepository {
  final RedditClient _client;

  SearchRepository(this._client);

  String _searchPath(String? subreddit) {
    if (subreddit == null || subreddit.isEmpty) {
      return '/search';
    }
    return '/r/$subreddit/search';
  }

  Map<String, String> _commonParams(String query, String? subreddit) {
    return {
      'q': query,
      if (subreddit != null && subreddit.isNotEmpty) 'restrict_sr': 'on',
    };
  }

  /// Searches for posts matching [query].
  Future<PaginatedResult<Post>> searchPosts(
    String query, {
    String? after,
    String? subreddit,
    SessionCookie? sessionCookie,
  }) async {
    for (final tryHtml in [true, false]) {
      try {
        if (tryHtml) {
          final params = _commonParams(query, subreddit);
          if (after != null) params['after'] = after;
          final html = await _client.getHtml(
            _searchPath(subreddit),
            queryParams: params,
            sessionCookie: sessionCookie,
          );
          final feed = HtmlSearchParser().parsePosts(html);
          return PaginatedResult<Post>(
            items: feed.posts,
            after: feed.after,
            hasMore: feed.hasMorePages,
          );
        }
      } catch (_) {
        if (!tryHtml) rethrow;
      }
    }
    throw RedditApiException(
      statusCode: 0,
      message: 'Search posts failed for query: $query',
    );
  }

  /// Searches for subreddits matching [query].
  Future<PaginatedResult<Subreddit>> searchCommunities(
    String query, {
    String? after,
    String? subreddit,
    SessionCookie? sessionCookie,
  }) async {
    final params = _commonParams(query, subreddit);
    params['type'] = 'sr';
    if (after != null) params['after'] = after;
    final html = await _client.getHtml(
      _searchPath(subreddit),
      queryParams: params,
      sessionCookie: sessionCookie,
    );
    final communities = HtmlSearchParser().parseCommunities(html);
    return PaginatedResult<Subreddit>(
      items: communities,
      after: null,
      hasMore: false,
    );
  }

  /// Searches for users matching [query].
  Future<PaginatedResult<SearchUser>> searchUsers(
    String query, {
    String? after,
    String? subreddit,
    SessionCookie? sessionCookie,
  }) async {
    final params = _commonParams(query, subreddit);
    params['type'] = 'user';
    if (after != null) params['after'] = after;
    final html = await _client.getHtml(
      _searchPath(subreddit),
      queryParams: params,
      sessionCookie: sessionCookie,
    );
    final users = HtmlSearchParser().parseUsers(html);
    return PaginatedResult<SearchUser>(
      items: users,
      after: null,
      hasMore: false,
    );
  }

  /// Searches for comments (returns posts with selftext as comment body).
  Future<PaginatedResult<Post>> searchComments(
    String query, {
    String? after,
    String? subreddit,
    SessionCookie? sessionCookie,
  }) async {
    return searchPosts(
      query,
      after: after,
      subreddit: subreddit,
      sessionCookie: sessionCookie,
    );
  }
}
