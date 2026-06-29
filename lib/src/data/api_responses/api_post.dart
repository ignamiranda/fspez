import '../../domain/models/post.dart';
import '../../domain/models/subreddit.dart';
import '../../domain/models/user_flair.dart';
import '../post_mapping.dart' as post_mapping;
import '../parsers/shared_parsers.dart';

class ApiPost {
  final String id;
  final String title;
  final String? selftext;
  final String? url;
  final String? thumbnail;
  final String author;
  final String subredditId;
  final String subreddit;
  final int score;
  final int numComments;
  final dynamic likes;
  final bool over18;
  final bool spoiler;
  final bool saved;
  final bool stickied;
  final bool locked;
  final int awardCount;
  final int createdUtc;
  final String permalink;
  final double? upvoteRatio;
  final Map<String, dynamic>? srDetail;
  final String? postHint;
  final bool? isGallery;
  final bool? isSelf;
  final String? crosspostParent;
  final List<String> mediaUrls;
  final String? videoUrl;
  final String? authorFlairText;
  final List<dynamic>? authorFlairRichtext;
  final String? authorFlairBackgroundColor;
  final String? authorFlairTextColor;
  final ApiPost? crosspostParentPost;

  ApiPost({
    required this.id,
    required this.title,
    this.selftext,
    this.url,
    this.thumbnail,
    required this.author,
    required this.subredditId,
    required this.subreddit,
    required this.score,
    required this.numComments,
    this.likes,
    required this.over18,
    required this.spoiler,
    required this.saved,
    required this.stickied,
    required this.locked,
    required this.awardCount,
    required this.createdUtc,
    required this.permalink,
    this.upvoteRatio,
    this.srDetail,
    this.postHint,
    this.isGallery,
    this.isSelf,
    this.crosspostParent,
    this.mediaUrls = const [],
    this.videoUrl,
    this.authorFlairText,
    this.authorFlairRichtext,
    this.authorFlairBackgroundColor,
    this.authorFlairTextColor,
    this.crosspostParentPost,
  });

  factory ApiPost.fromJson(Map<String, dynamic> data) {
    final mediaUrls = post_mapping.parseMediaUrls(data);
    final videoUrl = post_mapping.parseVideoUrl(data);
    final crosspostList = data['crosspost_parent_list'] as List<dynamic>?;
    final crosspostParentPost =
        (crosspostList != null && crosspostList.isNotEmpty)
            ? ApiPost.fromJson(crosspostList.first as Map<String, dynamic>)
            : null;
    return ApiPost(
      id: data['id'] as String,
      title: data['title'] as String? ?? '',
      selftext: data['selftext'] as String?,
      url: data['url'] as String?,
      thumbnail: data['thumbnail'] as String?,
      author: data['author'] as String? ?? '[deleted]',
      subredditId: data['subreddit_id'] as String? ?? '',
      subreddit: data['subreddit'] as String? ?? '',
      score: data['score'] as int? ?? 0,
      numComments: data['num_comments'] as int? ?? 0,
      likes: data['likes'],
      over18: data['over_18'] as bool? ?? false,
      spoiler: data['spoiler'] as bool? ?? false,
      saved: data['saved'] as bool? ?? false,
      stickied: data['stickied'] as bool? ?? false,
      locked: data['locked'] as bool? ?? false,
      awardCount: post_mapping.awardCount(data),
      createdUtc: (data['created_utc'] as num).toInt(),
      permalink: data['permalink'] as String? ?? '',
      upvoteRatio: (data['upvote_ratio'] as num?)?.toDouble(),
      srDetail: data['sr_detail'] as Map<String, dynamic>?,
      postHint: data['post_hint'] as String?,
      isGallery: data['is_gallery'] as bool?,
      isSelf: data['is_self'] as bool?,
      crosspostParent: data['crosspost_parent'] as String?,
      mediaUrls: mediaUrls,
      videoUrl: videoUrl,
      authorFlairText: data['author_flair_text'] as String?,
      authorFlairRichtext: data['author_flair_richtext'] as List<dynamic>?,
      authorFlairBackgroundColor:
          data['author_flair_background_color'] as String?,
      authorFlairTextColor: data['author_flair_text_color'] as String?,
      crosspostParentPost: crosspostParentPost,
    );
  }

  Post toDomain() {
    return Post(
      id: id,
      title: title,
      selftext: selftext,
      url: url,
      thumbnailUrl: post_mapping.cleanThumbnail(thumbnail),
      type: post_mapping.inferPostType(
        postHint: postHint,
        isGallery: isGallery,
        isSelf: isSelf,
        crosspostParent: crosspostParent,
      ),
      author: author,
      subreddit: Subreddit(
        id: subredditId,
        name: subreddit,
        iconUrl: post_mapping.subredditIcon(srDetail),
      ),
      score: score,
      commentCount: numComments,
      vote: parseVoteDirection(likes),
      isNsfw: over18,
      isSpoiler: spoiler,
      isSaved: saved,
      isStickied: stickied,
      isLocked: locked,
      awardCount: awardCount,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdUtc * 1000),
      permalink: permalink,
      upvoteRatio: upvoteRatio,
      crosspostParent: crosspostParentPost?.toDomain(),
      mediaUrls: mediaUrls,
      videoUrl: videoUrl,
      authorFlair: UserFlair.fromApi(
        text: authorFlairText,
        richtext: authorFlairRichtext,
        backgroundColor: authorFlairBackgroundColor,
        textColor: authorFlairTextColor,
      ),
    );
  }
}
