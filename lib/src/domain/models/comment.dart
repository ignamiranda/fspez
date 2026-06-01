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
  final int awardCount;
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
    this.awardCount = 0,
    required this.createdAt,
    required this.postId,
    this.parentId,
    this.depth = 0,
    this.replies = const [],
    this.isCollapsed = false,
    this.authorFlair,
  });

  Comment copyWith({
    String? id,
    String? body,
    String? author,
    int? score,
    VoteDirection? vote,
    bool? isSaved,
    bool? isSubmitter,
    bool? isModerator,
    bool? isStickied,
    int? awardCount,
    DateTime? createdAt,
    String? postId,
    String? parentId,
    int? depth,
    List<Comment>? replies,
    bool? isCollapsed,
    UserFlair? authorFlair,
  }) {
    return Comment(
      id: id ?? this.id,
      body: body ?? this.body,
      author: author ?? this.author,
      score: score ?? this.score,
      vote: vote ?? this.vote,
      isSaved: isSaved ?? this.isSaved,
      isSubmitter: isSubmitter ?? this.isSubmitter,
      isModerator: isModerator ?? this.isModerator,
      isStickied: isStickied ?? this.isStickied,
      awardCount: awardCount ?? this.awardCount,
      createdAt: createdAt ?? this.createdAt,
      postId: postId ?? this.postId,
      parentId: parentId ?? this.parentId,
      depth: depth ?? this.depth,
      replies: replies ?? this.replies,
      isCollapsed: isCollapsed ?? this.isCollapsed,
      authorFlair: authorFlair ?? this.authorFlair,
    );
  }

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
        awardCount,
        createdAt,
        postId,
        parentId,
        depth,
        replies,
        isCollapsed,
        authorFlair,
      ];
}
