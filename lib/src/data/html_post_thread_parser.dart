import '../domain/models/comment.dart';
import '../domain/models/post.dart';
import '../domain/models/post_detail.dart';
import '../domain/models/subreddit.dart';
import 'html_parser_utils.dart';
import 'shreddit_json_extractor.dart';

class HtmlPostThreadParser {
  PostDetail parse(String html) {
    final extracted = ShredditJsonExtractor.extract(html);

    final post = _extractPost(extracted);
    final comments = _extractComments(extracted);

    return PostDetail(post: post, comments: comments);
  }

  Post _extractPost(Map<String, dynamic> extracted) {
    final pp = pageProps(extracted);
    final rawPost = pp['post'] as Map<String, dynamic>?;
    if (rawPost == null) {
      return Post(
        id: '',
        title: '',
        author: '[deleted]',
        subreddit: const Subreddit(id: '', name: ''),
        createdAt: DateTime.now(),
        permalink: '',
        type: PostType.self_,
      );
    }

    return _postFromRaw(rawPost);
  }

  List<Comment> _extractComments(Map<String, dynamic> extracted) {
    final pp = pageProps(extracted);
    final rawComments = pp['comments'] as List<dynamic>?;
    if (rawComments == null) return [];

    return rawComments
        .whereType<Map<String, dynamic>>()
        .map(_commentFromRaw)
        .toList();
  }

  Post _postFromRaw(Map<String, dynamic> raw) {
    final id = raw['id'] as String? ?? '';
    final title = raw['title'] as String? ?? '';
    final author = raw['author'] as String? ?? '[deleted]';
    final subreddit = raw['subreddit'] as String? ?? '';
    final subredditId = raw['subreddit_id'] as String? ?? '';
    final score = intOr(raw, 'score') ?? 0;
    final numComments =
        intOr(raw, 'numComments') ?? intOr(raw, 'num_comments') ?? 0;
    final createdUtc =
        intOr(raw, 'createdUtc') ?? intOr(raw, 'created_utc') ?? 0;
    final permalink = raw['permalink'] as String? ?? '';

    return Post(
      id: id,
      title: title,
      selftext: raw['selftext'] as String?,
      url: raw['url'] as String?,
      thumbnailUrl: raw['thumbnail'] as String?,
      type: _inferType(raw),
      author: author,
      subreddit: Subreddit(id: subredditId, name: subreddit),
      score: score,
      commentCount: numComments,
      vote: parseVote(raw['likes']),
      isNsfw: boolOr(raw, 'over_18') ?? boolOr(raw, 'over18') ?? false,
      isSpoiler: boolOr(raw, 'spoiler') ?? false,
      isSaved: boolOr(raw, 'saved') ?? false,
      isStickied: boolOr(raw, 'stickied') ?? false,
      isLocked: boolOr(raw, 'locked') ?? false,
      awardCount: intOr(raw, 'totalAwardsReceived') ??
          intOr(raw, 'total_awards_received') ??
          0,
      createdAt: createdUtc > 0
          ? DateTime.fromMillisecondsSinceEpoch(createdUtc * 1000)
          : DateTime.now(),
      permalink: permalink,
      upvoteRatio:
          doubleOr(raw, 'upvoteRatio') ?? doubleOr(raw, 'upvote_ratio'),
      linkFlairText: (raw['linkFlairText'] as String?) ??
          (raw['link_flair_text'] as String?),
      linkFlairBackgroundColor: (raw['linkFlairBackgroundColor'] as String?) ??
          (raw['link_flair_background_color'] as String?),
      linkFlairTextColor: (raw['linkFlairTextColor'] as String?) ??
          (raw['link_flair_text_color'] as String?),
    );
  }

  Comment _commentFromRaw(Map<String, dynamic> raw) {
    final id = raw['id'] as String? ?? '';
    final body = raw['body'] as String? ?? '';
    final author = raw['author'] as String? ?? '[deleted]';
    final score = intOr(raw, 'score') ?? 0;
    final depth = intOr(raw, 'depth') ?? 0;
    final createdUtc =
        intOr(raw, 'createdUtc') ?? intOr(raw, 'created_utc') ?? 0;
    final linkId = raw['linkId'] as String? ?? raw['link_id'] as String? ?? '';
    final parentId = raw['parentId'] as String? ?? raw['parent_id'] as String?;

    final rawReplies = raw['replies'];
    List<Comment> replies;
    if (rawReplies is List) {
      replies = rawReplies
          .whereType<Map<String, dynamic>>()
          .map(_commentFromRaw)
          .toList();
    } else {
      replies = [];
    }

    return Comment(
      id: id,
      body: body,
      author: author,
      score: score,
      vote: parseVote(raw['likes']),
      isSaved: boolOr(raw, 'saved') ?? false,
      isSubmitter:
          boolOr(raw, 'isSubmitter') ?? boolOr(raw, 'is_submitter') ?? false,
      isModerator: (raw['distinguished'] as String?) == 'moderator',
      isAdmin: (raw['distinguished'] as String?) == 'admin',
      isApprovedSubmitter: (raw['distinguished'] as String?) == 'special',
      isControversial: (intOr(raw, 'controversiality') ?? 0) > 0,
      isScoreHidden:
          boolOr(raw, 'scoreHidden') ?? boolOr(raw, 'score_hidden') ?? false,
      isStickied: boolOr(raw, 'stickied') ?? false,
      awardCount: intOr(raw, 'totalAwardsReceived') ??
          intOr(raw, 'total_awards_received') ??
          0,
      createdAt: createdUtc > 0
          ? DateTime.fromMillisecondsSinceEpoch(createdUtc * 1000)
          : DateTime.now(),
      postId: linkId,
      parentId: parentId,
      depth: depth,
      replies: replies,
      isCollapsed: boolOr(raw, 'collapsed') ?? false,
      subreddit: raw['subreddit'] as String?,
      linkTitle: raw['linkTitle'] as String? ?? raw['link_title'] as String?,
      linkPermalink:
          raw['linkPermalink'] as String? ?? raw['link_permalink'] as String?,
    );
  }

  PostType _inferType(Map<String, dynamic> raw) {
    final postHint = raw['postHint'] as String? ?? raw['post_hint'] as String?;
    final isGallery = boolOr(raw, 'isGallery') ?? boolOr(raw, 'is_gallery');
    final isSelf = boolOr(raw, 'isSelf') ?? boolOr(raw, 'is_self');

    if (postHint == 'image') return PostType.image;
    if (postHint == 'hosted:video') return PostType.video;
    if (postHint == 'rich:video') return PostType.video;
    if (isGallery == true) return PostType.gallery;
    if (isSelf == true) return PostType.self_;
    return PostType.link;
  }
}
