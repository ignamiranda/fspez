import 'package:equatable/equatable.dart';
import '../../domain/enums/vote_direction.dart';
import 'user_flair.dart';

class Comment with EquatableMixin {
  final String id;
  final String body;
  final String author;
  final int score;
  final VoteDirection vote;
  final bool isSaved;
  final bool isSubmitter;
  final bool isModerator;
  final bool isStickied;
  final DateTime createdAt;
  final String postId;
  final String? parentId;
  final int depth;
  final List<Comment> replies;
  final bool isCollapsed;
  final UserFlair? authorFlair;

  String get fullname => 't1_$id';

  const Comment({
    required this.id,
    required this.body,
    required this.author,
    this.score = 0,
    this.vote = VoteDirection.none,
    this.isSaved = false,
    this.isSubmitter = false,
    this.isModerator = false,
    this.isStickied = false,
    required this.createdAt,
    required this.postId,
    this.parentId,
    this.depth = 0,
    this.replies = const [],
    this.isCollapsed = false,
    this.authorFlair,
  });

  @override
  List<Object?> get props => [
        id,
        body,
        author,
        score,
        vote,
        isSaved,
        isSubmitter,
        isModerator,
        isStickied,
        createdAt,
        postId,
        parentId,
        depth,
        replies,
        isCollapsed,
        authorFlair,
      ];
}
