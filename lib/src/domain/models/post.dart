import 'package:equatable/equatable.dart';
import '../../domain/enums/vote_direction.dart';
import 'award_data.dart';
import 'subreddit.dart';
import 'user_flair.dart';

enum PostType { link, self_, image, gallery, video, crosspost, poll }

class Post with Equatable {
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
  final int awardCount;
  final List<AwardData> awards;
  final DateTime createdAt;
  final String permalink;
  final double? upvoteRatio;
  final Post? crosspostParent;
  final List<String> mediaUrls;
  final String? videoUrl;
  final String? linkFlairText;
  final String? linkFlairBackgroundColor;
  final String? linkFlairTextColor;
  final UserFlair? authorFlair;

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
    this.awardCount = 0,
    this.awards = const [],
    required this.createdAt,
    required this.permalink,
    this.upvoteRatio,
    this.crosspostParent,
    this.mediaUrls = const [],
    this.videoUrl,
    this.linkFlairText,
    this.linkFlairBackgroundColor,
    this.linkFlairTextColor,
    this.authorFlair,
  });

  Post copyWith({
    String? id,
    String? title,
    String? selftext,
    String? url,
    String? thumbnailUrl,
    PostType? type,
    String? author,
    Subreddit? subreddit,
    int? score,
    int? commentCount,
    VoteDirection? vote,
    bool? isNsfw,
    bool? isSpoiler,
    bool? isSaved,
    bool? isStickied,
    bool? isLocked,
    int? awardCount,
    List<AwardData>? awards,
    DateTime? createdAt,
    String? permalink,
    double? upvoteRatio,
    Post? crosspostParent,
    List<String>? mediaUrls,
    String? videoUrl,
    String? linkFlairText,
    String? linkFlairBackgroundColor,
    String? linkFlairTextColor,
    UserFlair? authorFlair,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      selftext: selftext ?? this.selftext,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      type: type ?? this.type,
      author: author ?? this.author,
      subreddit: subreddit ?? this.subreddit,
      score: score ?? this.score,
      commentCount: commentCount ?? this.commentCount,
      vote: vote ?? this.vote,
      isNsfw: isNsfw ?? this.isNsfw,
      isSpoiler: isSpoiler ?? this.isSpoiler,
      isSaved: isSaved ?? this.isSaved,
      isStickied: isStickied ?? this.isStickied,
      isLocked: isLocked ?? this.isLocked,
      awardCount: awardCount ?? this.awardCount,
      awards: awards ?? this.awards,
      createdAt: createdAt ?? this.createdAt,
      permalink: permalink ?? this.permalink,
      upvoteRatio: upvoteRatio ?? this.upvoteRatio,
      crosspostParent: crosspostParent ?? this.crosspostParent,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      videoUrl: videoUrl ?? this.videoUrl,
      linkFlairText: linkFlairText ?? this.linkFlairText,
      linkFlairBackgroundColor:
          linkFlairBackgroundColor ?? this.linkFlairBackgroundColor,
      linkFlairTextColor: linkFlairTextColor ?? this.linkFlairTextColor,
      authorFlair: authorFlair ?? this.authorFlair,
    );
  }

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
        awardCount,
        awards,
        createdAt,
        permalink,
        upvoteRatio,
        crosspostParent,
        mediaUrls,
        videoUrl,
        linkFlairText,
        linkFlairBackgroundColor,
        linkFlairTextColor,
        authorFlair,
      ];
}
