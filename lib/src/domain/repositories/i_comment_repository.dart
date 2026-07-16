import '../enums/comment_sort.dart';
import '../models/post_detail.dart';
import '../models/session_cookie.dart';

abstract class ICommentRepository {
  Future<PostDetail> fetchComments(
    String subreddit,
    String postId, {
    CommentSort? sort,
    SessionCookie? sessionCookie,
  });

  Future<void> reply({
    required String thingId,
    required String text,
    required SessionCookie sessionCookie,
  });

  Future<void> edit({
    required String thingId,
    required String text,
    required SessionCookie sessionCookie,
  });
}
