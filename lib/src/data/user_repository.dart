import '../domain/models/session_cookie.dart';
import '../domain/models/user_profile.dart';
import '../domain/models/user_comment.dart';
import 'parsers/shared_parsers.dart';
import 'reddit_client.dart';

class UserRepository {
  final RedditClient _client;

  UserRepository(this._client);

  Future<UserProfile> fetchProfile(
    String username, {
    SessionCookie? sessionCookie,
  }) async {
    final data = await _client.get('/user/$username/about',
        sessionCookie: sessionCookie);
    final about = data['data'] as Map<String, dynamic>;

    return UserProfile(
      username: about['name'] as String? ?? username,
      linkKarma: about['link_karma'] as int? ?? 0,
      commentKarma: about['comment_karma'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (about['created_utc'] as num).toInt() * 1000,
      ),
      iconUrl: _iconUrl(about),
      isGold: about['is_gold'] as bool? ?? false,
      isMod: about['is_mod'] as bool? ?? false,
      subredditName: (about['subreddit'] as Map<String, dynamic>?)?
          ['name'] as String?,
    );
  }

  Future<List<UserComment>> fetchComments(
    String username, {
    String? after,
    SessionCookie? sessionCookie,
  }) async {
    final data = await _client.get('/user/$username/comments',
        queryParams: {
          if (after != null) 'after': after,
          'limit': '25',
          'sort': 'new',
        },
        sessionCookie: sessionCookie);

    final listing = data['data'] as Map<String, dynamic>;
    final children = listing['children'] as List<dynamic>;

    final comments = children
        .whereType<Map<String, dynamic>>()
        .where((child) => child['kind'] == 't1')
        .map((child) => _parseComment(child['data'] as Map<String, dynamic>))
        .toList();

    return comments;
  }

  String? _iconUrl(Map<String, dynamic> about) {
    final raw = about['icon_img'] as String?;
    if (raw != null && raw.isNotEmpty) return raw.replaceAll('&amp;', '&');
    return null;
  }

  UserComment _parseComment(Map<String, dynamic> data) {
    return UserComment(
      id: data['id'] as String? ?? '',
      body: data['body'] as String? ?? '',
      author: data['author'] as String? ?? '[deleted]',
      score: data['score'] as int? ?? 0,
      vote: parseVoteDirection(data['likes']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (data['created_utc'] as num).toInt() * 1000,
      ),
      subreddit: data['subreddit'] as String? ?? '',
      linkTitle: data['link_title'] as String? ?? '',
      linkPermalink: data['link_permalink'] as String? ?? '',
      postId: data['link_id'] as String? ?? '',
    );
  }
}
