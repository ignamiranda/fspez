import 'package:equatable/equatable.dart';
import '../../domain/enums/vote_direction.dart';
import 'user_flair.dart';

class Comment with Equatable {
  final String id;
  final String body;
  final String author;
  final int score;
  final VoteDirection vote;
  final bool isSaved;
  final bool isSubmitter;
  final bool isModerator;
  final bool isAdmin;
  final bool isApprovedSubmitter;
  final bool isControversial;
  final bool isScoreHidden;
  final bool isStickied;
  final int awardCount;
  final DateTime createdAt;
  final String postId;
  final String? parentId;
  final int depth;
  final List<Comment> replies;
  final bool isCollapsed;
  final UserFlair? authorFlair;
  final String? subreddit;
  final String? linkTitle;
  final String? linkPermalink;

  /// API "more" placeholder fields (false/0 by default for regular comments).
  /// When true, this Comment represents a "load more replies" placeholder
  /// from the API (kind: "more"), not an actual comment.
  final bool isMorePlaceholder;

  /// Number of additional replies represented by this placeholder.
  final int moreCount;

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
    this.isAdmin = false,
    this.isApprovedSubmitter = false,
    this.isControversial = false,
    this.isScoreHidden = false,
    this.isStickied = false,
    this.awardCount = 0,
    required this.createdAt,
    required this.postId,
    this.parentId,
    this.depth = 0,
    this.replies = const [],
    this.isCollapsed = false,
    this.authorFlair,
    this.subreddit,
    this.linkTitle,
    this.linkPermalink,
    this.isMorePlaceholder = false,
    this.moreCount = 0,
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
    bool? isAdmin,
    bool? isApprovedSubmitter,
    bool? isControversial,
    bool? isScoreHidden,
    bool? isStickied,
    int? awardCount,
    DateTime? createdAt,
    String? postId,
    String? parentId,
    int? depth,
    List<Comment>? replies,
    bool? isCollapsed,
    UserFlair? authorFlair,
    String? subreddit,
    String? linkTitle,
    String? linkPermalink,
    bool? isMorePlaceholder,
    int? moreCount,
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
      isAdmin: isAdmin ?? this.isAdmin,
      isApprovedSubmitter: isApprovedSubmitter ?? this.isApprovedSubmitter,
      isControversial: isControversial ?? this.isControversial,
      isScoreHidden: isScoreHidden ?? this.isScoreHidden,
      isStickied: isStickied ?? this.isStickied,
      awardCount: awardCount ?? this.awardCount,
      createdAt: createdAt ?? this.createdAt,
      postId: postId ?? this.postId,
      parentId: parentId ?? this.parentId,
      depth: depth ?? this.depth,
      replies: replies ?? this.replies,
      isCollapsed: isCollapsed ?? this.isCollapsed,
      authorFlair: authorFlair ?? this.authorFlair,
      subreddit: subreddit ?? this.subreddit,
      linkTitle: linkTitle ?? this.linkTitle,
      linkPermalink: linkPermalink ?? this.linkPermalink,
      isMorePlaceholder: isMorePlaceholder ?? this.isMorePlaceholder,
      moreCount: moreCount ?? this.moreCount,
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
        isAdmin,
        isApprovedSubmitter,
        isControversial,
        isScoreHidden,
        isStickied,
        awardCount,
        createdAt,
        postId,
        parentId,
        depth,
        replies,
        isCollapsed,
        authorFlair,
        subreddit,
        linkTitle,
        linkPermalink,
        isMorePlaceholder,
        moreCount,
      ];
}
