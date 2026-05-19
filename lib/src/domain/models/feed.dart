import 'package:equatable/equatable.dart';
import '../../domain/enums/feed_sort.dart';
import 'post.dart';

enum FeedKind { home, popular, all_, multireddit, saved }

class Feed with EquatableMixin {
  final FeedKind kind;
  final FeedSort sort;
  final List<Post> posts;
  final String? after;
  final String? before;
  final String? multiredditName;

  const Feed({
    required this.kind,
    this.sort = FeedSort.best,
    this.posts = const [],
    this.after,
    this.before,
    this.multiredditName,
  });

  bool get hasMorePages => after != null;

  @override
  List<Object?> get props => [
        kind,
        sort,
        posts,
        after,
        before,
        multiredditName,
      ];
}
