import 'comment.dart';
import 'post.dart';

class PostDetail {
  final Post post;
  final List<Comment> comments;

  const PostDetail({required this.post, required this.comments});
}
