import '../domain/models/session_cookie.dart';
import '../domain/models/user_profile.dart';
import '../domain/models/comment.dart';
import '../domain/enums/comment_sort.dart';
import '../domain/repositories/i_user_repository.dart';
import 'reddit_client.dart';
import 'parsers/shared_parsers.dart';

class UserRepository implements IUserRepository {
  final RedditClient _client;

  UserRepository(this._client);

  @override
  Future<UserProfile> fetchProfile(
    String username, {
    SessionCookie? sessionCookie,
  }) async {
    final data = await _client.get(
      '/user/$username/about',
      sessionCookie: sessionCookie,
    );
    final about = data['data'] as Map<String, dynamic>;

    return UserProfile(
      id: about['id'] as String? ?? '',
      username: about['name'] as String? ?? username,
      linkKarma: about['link_karma'] as int? ?? 0,
      commentKarma: about['comment_karma'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (about['created_utc'] as num).toInt() * 1000,
      ),
      iconUrl: _iconUrl(about),
      isGold: about['is_gold'] as bool? ?? false,
      isMod: about['is_mod'] as bool? ?? false,
    );
  }

  @override
  Future<List<Comment>> fetchComments(
    String username, {
    String? after,
    CommentSort sort = CommentSort.new_,
    SessionCookie? sessionCookie,
  }) async {
    final data = await _client.get(
      '/user/$username/comments',
      queryParams: {
        if (after != null) 'after': after,
        'limit': '25',
        'sort': sort.queryValue,
      },
      sessionCookie: sessionCookie,
    );

    final listing = data['data'] as Map<String, dynamic>;
    final children = listing['children'] as List<dynamic>;

    return children
        .whereType<Map<String, dynamic>>()
        .where((child) => child['kind'] == 't1')
        .map((child) => _parseComment(child['data'] as Map<String, dynamic>))
        .toList();
  }

  /// Fetches subreddits the authenticated user moderates.
  ///
  /// Requires a valid session cookie. Returns display names only
  /// (e.g., ["flutter", "dartlang"]).
  @override
  Future<List<String>> fetchModeratedSubreddits({
    required SessionCookie sessionCookie,
  }) async {
    final data = await _client.get(
      '/subreddits/mine/moderator',
      sessionCookie: sessionCookie,
    );
    final listing = data['data'] as Map<String, dynamic>? ?? {};
    final children = listing['children'] as List<dynamic>? ?? [];
    return children
        .whereType<Map<String, dynamic>>()
        .map((c) => c['data'] as Map<String, dynamic>? ?? {})
        .where((d) => d['display_name'] != null)
        .map((d) => d['display_name'] as String)
        .toList();
  }

  String? _iconUrl(Map<String, dynamic> about) {
    final raw = about['icon_img'] as String?;
    if (raw != null && raw.isNotEmpty) return raw.replaceAll('&amp;', '&');
    return null;
  }

  Comment _parseComment(Map<String, dynamic> data) {
    return commentFromApiData(data);
  }
}
