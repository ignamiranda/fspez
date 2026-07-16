import '../models/post.dart';
import '../models/subreddit.dart';
import '../models/search_user.dart';
import '../models/session_cookie.dart';
import '../models/paginated_result.dart';

abstract class ISearchRepository {
  Future<PaginatedResult<Post>> searchPosts(
    String query, {
    String? after,
    String? subreddit,
    SessionCookie? sessionCookie,
  });

  Future<PaginatedResult<Subreddit>> searchCommunities(
    String query, {
    String? after,
    String? subreddit,
    SessionCookie? sessionCookie,
  });

  Future<PaginatedResult<SearchUser>> searchUsers(
    String query, {
    String? after,
    String? subreddit,
    SessionCookie? sessionCookie,
  });

  Future<PaginatedResult<Post>> searchComments(
    String query, {
    String? after,
    String? subreddit,
    SessionCookie? sessionCookie,
  });
}
