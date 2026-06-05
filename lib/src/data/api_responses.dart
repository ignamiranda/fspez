import '../domain/models/post.dart';
import '../domain/models/search_user.dart';
import '../domain/models/subreddit.dart';
import '../domain/models/subreddit_rule.dart';
import '../domain/models/user_flair.dart';
import 'post_mapping.dart' as post_mapping;
import 'parsers/shared_parsers.dart';

class ApiListing {
  final String? after;
  final String? before;
  final List<ApiPost> children;

  ApiListing({this.after, this.before, required this.children});

  factory ApiListing.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final children = (data['children'] as List<dynamic>)
        .map((c) => ApiPost.fromJson(c['data'] as Map<String, dynamic>))
        .toList();
    return ApiListing(
      after: data['after'] as String?,
      before: data['before'] as String?,
      children: children,
    );
  }

  factory ApiListing.fromListing(Map<String, dynamic> json) {
    return ApiListing.fromJson(json);
  }
}

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

class ApiSearchUser {
  final String name;
  final int linkKarma;
  final int commentKarma;
  final String? iconImg;
  final bool isGold;
  final bool isMod;

  ApiSearchUser({
    required this.name,
    required this.linkKarma,
    required this.commentKarma,
    this.iconImg,
    required this.isGold,
    required this.isMod,
  });

  factory ApiSearchUser.fromJson(Map<String, dynamic> data) {
    return ApiSearchUser(
      name: data['name'] as String? ?? '',
      linkKarma: data['link_karma'] as int? ?? 0,
      commentKarma: data['comment_karma'] as int? ?? 0,
      iconImg: data['icon_img'] as String?,
      isGold: data['is_gold'] as bool? ?? false,
      isMod: data['is_mod'] as bool? ?? false,
    );
  }

  SearchUser toDomain() {
    return SearchUser(
      name: name,
      linkKarma: linkKarma,
      commentKarma: commentKarma,
      iconImg: iconImg?.replaceAll('&amp;', '&'),
      isGold: isGold,
      isMod: isMod,
    );
  }
}

class ApiComment {
  final String id;
  final String body;
  final String author;
  final int score;
  final dynamic likes;
  final bool saved;
  final bool isSubmitter;
  final String? distinguished;
  final bool stickied;
  final int awardCount;
  final int createdUtc;
  final String linkId;
  final String? parentId;
  final int depth;
  final bool collapsed;
  final List<ApiComment> replies;
  final String? authorFlairText;
  final List<dynamic>? authorFlairRichtext;
  final String? authorFlairBackgroundColor;
  final String? authorFlairTextColor;
  final String? linkTitle;
  final String? linkPermalink;
  final String? commentSubreddit;

  ApiComment({
    required this.id,
    required this.body,
    required this.author,
    required this.score,
    this.likes,
    required this.saved,
    required this.isSubmitter,
    this.distinguished,
    required this.stickied,
    required this.awardCount,
    required this.createdUtc,
    required this.linkId,
    this.parentId,
    required this.depth,
    required this.collapsed,
    required this.replies,
    this.authorFlairText,
    this.authorFlairRichtext,
    this.authorFlairBackgroundColor,
    this.authorFlairTextColor,
    this.linkTitle,
    this.linkPermalink,
    this.commentSubreddit,
  });

  factory ApiComment.fromJson(Map<String, dynamic> data) {
    final repliesRaw = data['replies'];
    List<ApiComment> replies;
    if (repliesRaw is Map<String, dynamic> && repliesRaw['kind'] == 'Listing') {
      final children = (repliesRaw['data'] as Map<String, dynamic>)['children']
          as List<dynamic>;
      replies = children
          .whereType<Map<String, dynamic>>()
          .where((c) => c['kind'] == 't1')
          .map((c) => ApiComment.fromJson(c['data'] as Map<String, dynamic>))
          .toList();
    } else {
      replies = [];
    }

    return ApiComment(
      id: data['id'] as String? ?? '',
      body: data['body'] as String? ?? '',
      author: data['author'] as String? ?? '[deleted]',
      score: data['score'] as int? ?? 0,
      likes: data['likes'],
      saved: data['saved'] as bool? ?? false,
      isSubmitter: data['is_submitter'] as bool? ?? false,
      distinguished: data['distinguished'] as String?,
      stickied: data['stickied'] as bool? ?? false,
      awardCount: post_mapping.awardCount(data),
      createdUtc: (data['created_utc'] as num).toInt(),
      linkId: data['link_id'] as String? ?? '',
      parentId: data['parent_id'] as String?,
      depth: data['depth'] as int? ?? 0,
      collapsed: data['collapsed'] as bool? ?? false,
      replies: replies,
      authorFlairText: data['author_flair_text'] as String?,
      authorFlairRichtext: data['author_flair_richtext'] as List<dynamic>?,
      authorFlairBackgroundColor:
          data['author_flair_background_color'] as String?,
      authorFlairTextColor: data['author_flair_text_color'] as String?,
      linkTitle: data['link_title'] as String?,
      linkPermalink: data['link_permalink'] as String?,
      commentSubreddit: data['subreddit'] as String?,
    );
  }
}

class ApiMessage {
  final String id;
  final String subject;
  final String body;
  final String author;
  final String dest;
  final int createdUtc;
  final bool isNew;
  final bool wasComment;
  final String? parentId;
  final String? subreddit;
  final String? distinguished;
  final dynamic likes;
  final int score;
  final String? context;
  final String? firstMessageName;
  final List<ApiMessage> replies;

  ApiMessage({
    required this.id,
    required this.subject,
    required this.body,
    required this.author,
    required this.dest,
    required this.createdUtc,
    required this.isNew,
    required this.wasComment,
    this.parentId,
    this.subreddit,
    this.distinguished,
    this.likes,
    required this.score,
    this.context,
    this.firstMessageName,
    required this.replies,
  });

  factory ApiMessage.fromJson(Map<String, dynamic> data) {
    final repliesRaw = data['replies'];
    List<ApiMessage> replies;
    if (repliesRaw is Map<String, dynamic> && repliesRaw['kind'] == 'Listing') {
      final children = (repliesRaw['data'] as Map<String, dynamic>)['children']
          as List<dynamic>;
      replies = children
          .whereType<Map<String, dynamic>>()
          .where((c) => c['kind'] == 't4' || c['kind'] == 't1')
          .map((c) => ApiMessage.fromJson(c['data'] as Map<String, dynamic>))
          .toList();
    } else {
      replies = [];
    }

    return ApiMessage(
      id: data['id'] as String? ?? '',
      subject: data['subject'] as String? ?? '(no subject)',
      body: data['body'] as String? ?? '',
      author: data['author'] as String? ?? '[deleted]',
      dest: data['dest'] as String? ?? '',
      createdUtc: (data['created_utc'] as num).toInt(),
      isNew: data['new'] as bool? ?? false,
      wasComment: data['was_comment'] as bool? ?? false,
      parentId: data['parent_id'] as String?,
      subreddit: data['subreddit'] as String?,
      distinguished: data['distinguished'] as String?,
      likes: data['likes'],
      score: data['score'] as int? ?? 0,
      context: data['context'] as String?,
      firstMessageName: data['first_message_name'] as String?,
      replies: replies,
    );
  }
}

class ApiSubreddit {
  final String id;
  final String displayName;
  final String? publicDescription;
  final String? description;
  final int subscribers;
  final int? activeUserCount;
  final int? createdUtc;
  final bool over18;
  final bool quarantine;
  final bool userIsSubscriber;
  final String? subredditType;
  final String? iconImg;
  final String? communityIcon;
  final String? bannerImg;
  final String? bannerBackgroundImage;

  ApiSubreddit({
    required this.id,
    required this.displayName,
    this.publicDescription,
    this.description,
    required this.subscribers,
    this.activeUserCount,
    this.createdUtc,
    required this.over18,
    required this.quarantine,
    required this.userIsSubscriber,
    this.subredditType,
    this.iconImg,
    this.communityIcon,
    this.bannerImg,
    this.bannerBackgroundImage,
  });

  factory ApiSubreddit.fromJson(Map<String, dynamic> data) {
    return ApiSubreddit(
      id: data['id'] as String? ?? '',
      displayName: data['display_name'] as String? ?? '',
      publicDescription: data['public_description'] as String?,
      description: data['description'] as String?,
      subscribers: data['subscribers'] as int? ?? 0,
      activeUserCount: (data['active_user_count'] as num?)?.toInt(),
      createdUtc: (data['created_utc'] as num?)?.toInt(),
      over18: data['over18'] as bool? ?? false,
      quarantine: data['quarantine'] as bool? ?? false,
      userIsSubscriber: data['user_is_subscriber'] as bool? ?? false,
      subredditType: data['subreddit_type'] as String?,
      iconImg: data['icon_img'] as String?,
      communityIcon: data['community_icon'] as String?,
      bannerImg: data['banner_img'] as String?,
      bannerBackgroundImage: data['banner_background_image'] as String?,
    );
  }

  Subreddit toDomain(String fallbackName) {
    return Subreddit(
      id: id,
      name: displayName.isNotEmpty ? displayName : fallbackName,
      description: publicDescription,
      sidebarDescription: description,
      subscriberCount: subscribers,
      activeUserCount: activeUserCount,
      createdAt: createdUtc == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(createdUtc! * 1000),
      isNsfw: over18,
      isQuarantined: quarantine,
      isSubscribed: userIsSubscriber,
      subredditType: subredditType,
      iconUrl: _iconUrl(),
      bannerUrl: bannerImg ?? bannerBackgroundImage,
    );
  }

  String? _iconUrl() {
    final raw = iconImg;
    if (raw != null && raw.isNotEmpty) {
      return raw.replaceAll('&amp;', '&');
    }
    final fallback = communityIcon;
    if (fallback != null && fallback.isNotEmpty) {
      return fallback.replaceAll('&amp;', '&');
    }
    return null;
  }
}

class ApiSubredditRules {
  final List<ApiSubredditRule> rules;

  const ApiSubredditRules({required this.rules});

  factory ApiSubredditRules.fromJson(Map<String, dynamic> data) {
    final rules = (data['rules'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ApiSubredditRule.fromJson)
        .toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));

    return ApiSubredditRules(rules: rules);
  }

  List<SubredditRule> toDomain() =>
      rules.map((rule) => rule.toDomain()).toList();
}

class ApiSubredditRule {
  final String shortName;
  final String description;
  final String kind;
  final String? violationReason;
  final int priority;

  const ApiSubredditRule({
    required this.shortName,
    required this.description,
    required this.kind,
    this.violationReason,
    required this.priority,
  });

  factory ApiSubredditRule.fromJson(Map<String, dynamic> data) {
    return ApiSubredditRule(
      shortName: data['short_name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      kind: data['kind'] as String? ?? 'all',
      violationReason: data['violation_reason'] as String?,
      priority: (data['priority'] as num?)?.toInt() ?? 0,
    );
  }

  SubredditRule toDomain() {
    return SubredditRule(
      shortName: shortName,
      description: description,
      kind: kind,
      violationReason: violationReason,
      priority: priority,
    );
  }
}
