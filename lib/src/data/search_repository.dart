import '../domain/models/feed.dart';
import '../domain/models/post.dart';
import '../domain/models/subreddit.dart';
import '../domain/models/search_user.dart';
import '../domain/models/session_cookie.dart';
import '../domain/enums/feed_sort.dart';
import 'reddit_client.dart';
import 'feed_parser.dart';
import 'api_responses.dart';
import 'paginated_notifier.dart';

class SearchRepository {
  final RedditClient _client;
  final FeedParser _parser;

  SearchRepository(this._client, {FeedParser? parser})
      : _parser = parser ?? FeedParser();

  String _searchPath(String? subreddit) {
    if (subreddit == null || subreddit.isEmpty) {
      return '/search';
    }
    return '/r/$subreddit/search';
  }

  /// Searches for posts matching [query].
  Future<PaginatedResult<Post>> searchPosts(
    String query, {
    String? after,
    String? subreddit,
    SessionCookie? sessionCookie,
  }) async {
    final page = await _search(query,
        after: after, subreddit: subreddit, sessionCookie: sessionCookie);
    return PaginatedResult<Post>(
      items: page.posts,
      after: page.after,
      hasMore: page.hasMorePages,
    );
  }

  /// Searches for subreddits matching [query].
  Future<PaginatedResult<Subreddit>> searchCommunities(
    String query, {
    String? after,
    String? subreddit,
    SessionCookie? sessionCookie,
  }) async {
    final data = await _client.get(_searchPath(subreddit),
        queryParams: {
          'q': query,
          'type': 'sr',
          if (subreddit != null && subreddit.isNotEmpty) 'restrict_sr': 'on',
          'sort': 'relevance',
          'limit': '25',
          if (after != null) 'after': after,
        },
        sessionCookie: sessionCookie);

    final listing = data['data'] as Map<String, dynamic>;
    final children = (listing['children'] as List<dynamic>)
        .map((c) => c['data'] as Map<String, dynamic>)
        .toList();

    final subreddits =
        children.map((c) => ApiSubreddit.fromJson(c).toDomain('')).toList();

    return PaginatedResult<Subreddit>(
      items: subreddits,
      after: listing['after'] as String?,
      hasMore: listing['after'] != null,
    );
  }

  /// Searches for users matching [query].
  Future<PaginatedResult<SearchUser>> searchUsers(
    String query, {
    String? after,
    String? subreddit,
    SessionCookie? sessionCookie,
  }) async {
    final data = await _client.get(_searchPath(subreddit),
        queryParams: {
          'q': query,
          'type': 'user',
          if (subreddit != null && subreddit.isNotEmpty) 'restrict_sr': 'on',
          'sort': 'relevance',
          'limit': '25',
          if (after != null) 'after': after,
        },
        sessionCookie: sessionCookie);

    final listing = data['data'] as Map<String, dynamic>;
    final children = (listing['children'] as List<dynamic>)
        .map((c) => c['data'] as Map<String, dynamic>)
        .toList();

    final users =
        children.map((c) => ApiSearchUser.fromJson(c).toDomain()).toList();

    return PaginatedResult<SearchUser>(
      items: users,
      after: listing['after'] as String?,
      hasMore: listing['after'] != null,
    );
  }

  /// Searches for comments (returns posts with selftext as comment body).
  Future<PaginatedResult<Post>> searchComments(
    String query, {
    String? after,
    String? subreddit,
    SessionCookie? sessionCookie,
  }) async {
    // Comment search via JSON API returns t3 posts, not comments.
    // We reuse searchPosts and render selftext as comment body.
    return searchPosts(
      query,
      after: after,
      subreddit: subreddit,
      sessionCookie: sessionCookie,
    );
  }

  Future<Feed> _search(
    String query, {
    String? after,
    String? subreddit,
    SessionCookie? sessionCookie,
  }) async {
    final data = await _client.get(_searchPath(subreddit),
        queryParams: {
          'q': query,
          'restrict_sr':
              subreddit != null && subreddit.isNotEmpty ? 'on' : 'off',
          'sort': 'relevance',
          'limit': '25',
          'sr_detail': 'true',
          if (after != null) 'after': after,
        },
        sessionCookie: sessionCookie);
    return _parser.parseFeed(data, FeedKind.popular, FeedSort.new_);
  }
}
