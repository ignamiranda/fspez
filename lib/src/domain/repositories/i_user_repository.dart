import '../enums/comment_sort.dart';
import '../models/comment.dart';
import '../models/session_cookie.dart';
import '../models/user_profile.dart';

abstract class IUserRepository {
  Future<UserProfile> fetchProfile(
    String username, {
    SessionCookie? sessionCookie,
  });

  Future<List<Comment>> fetchComments(
    String username, {
    String? after,
    CommentSort sort = CommentSort.new_,
    SessionCookie? sessionCookie,
  });

  Future<List<String>> fetchModeratedSubreddits({
    required SessionCookie sessionCookie,
  });
}
