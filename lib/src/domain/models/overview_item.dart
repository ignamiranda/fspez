import 'post.dart';
import 'comment.dart';

sealed class OverviewItem {
  const OverviewItem();
}

class OverviewPost extends OverviewItem {
  final Post post;

  const OverviewPost(this.post);
}

class OverviewComment extends OverviewItem {
  final Comment comment;

  const OverviewComment(this.comment);
}
