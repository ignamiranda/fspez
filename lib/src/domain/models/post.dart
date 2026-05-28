import 'package:equatable/equatable.dart';
import '../../domain/enums/vote_direction.dart';
import 'subreddit.dart';

enum PostType { link, self_, image, gallery, video, crosspost, poll }

class Post with EquatableMixin {
  final String id;
  final String title;
  final String? selftext;
  final String? url;
  final String? thumbnailUrl;
  final PostType type;
  final String author;
  final Subreddit subreddit;
  final int score;
  final int commentCount;
  final VoteDirection vote;
  final bool isNsfw;
  final bool isSpoiler;
  final bool isSaved;
  final bool isStickied;
  final bool isLocked;
  final DateTime createdAt;
  final String permalink;
  final double? upvoteRatio;
  final Post? crosspostParent;
  final List<String> mediaUrls;
  final String? videoUrl;

  String get fullname => 't3_$id';

  const Post({
    required this.id,
    required this.title,
    this.selftext,
    this.url,
    this.thumbnailUrl,
    required this.type,
    required this.author,
    required this.subreddit,
    this.score = 0,
    this.commentCount = 0,
    this.vote = VoteDirection.none,
    this.isNsfw = false,
    this.isSpoiler = false,
    this.isSaved = false,
    this.isStickied = false,
    this.isLocked = false,
    required this.createdAt,
    required this.permalink,
    this.upvoteRatio,
    this.crosspostParent,
    this.mediaUrls = const [],
    this.videoUrl,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        selftext,
        url,
        thumbnailUrl,
        type,
        author,
        subreddit,
        score,
        commentCount,
        vote,
        isNsfw,
        isSpoiler,
        isSaved,
        isStickied,
        isLocked,
        createdAt,
        permalink,
        upvoteRatio,
        crosspostParent,
        mediaUrls,
        videoUrl,
      ];
}
