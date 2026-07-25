import '../domain/models/session_cookie.dart';
import '../domain/models/user_profile.dart';
import '../domain/models/comment.dart';
import '../domain/enums/comment_sort.dart';
import 'html_moderator_parser.dart';
import 'html_user_profile_parser.dart';
import 'reddit_client.dart';

class UserRepository {
  final RedditClient _client;

  UserRepository(this._client);

  Future<UserProfile> fetchProfile(
    String username, {
    SessionCookie? sessionCookie,
  }) async {
    final html = await _client.getHtml(
      '/user/$username',
      sessionCookie: sessionCookie,
    );
    return HtmlUserProfileParser().parseProfile(html, username);
  }

  Future<List<Comment>> fetchComments(
    String username, {
    String? after,
    CommentSort sort = CommentSort.new_,
    SessionCookie? sessionCookie,
  }) async {
    final html = await _client.getHtml(
      '/user/$username/comments',
      queryParams: {
        if (after != null) 'after': after,
        'sort': sort.queryValue,
      },
      sessionCookie: sessionCookie,
    );
    return HtmlUserProfileParser().parseComments(html);
  }

  /// Fetches subreddits the authenticated user moderates.
  ///
  /// Requires a valid session cookie. Returns display names only
  /// (e.g., ["flutter", "dartlang"]).
  Future<List<String>> fetchModeratedSubreddits({
    required SessionCookie sessionCookie,
  }) async {
    final html = await _client.getHtml(
      '/subreddits/mine/moderator',
      sessionCookie: sessionCookie,
    );
    return HtmlModeratorParser().parseModeratedSubreddits(html);
  }
}
