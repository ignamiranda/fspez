import '../domain/enums/vote_direction.dart';
import '../domain/models/comment.dart';
import '../domain/models/post.dart';
import '../domain/models/post_detail.dart';
import '../domain/models/subreddit.dart';
import 'shreddit_json_extractor.dart';

class HtmlPostThreadParser {
  PostDetail parse(String html) {
    final extracted = ShredditJsonExtractor.extract(html);
    final pageProps = _pageProps(extracted);

    final post = _extractPost(pageProps);
    final comments = _extractComments(pageProps);

    return PostDetail(post: post, comments: comments);
  }

  Post _extractPost(Map<String, dynamic> pageProps) {
    final rawPost = pageProps['post'] as Map<String, dynamic>?;
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

  List<Comment> _extractComments(Map<String, dynamic> pageProps) {
    final rawComments = pageProps['comments'] as List<dynamic>?;
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
    final score = _int(raw, 'score') ?? 0;
    final numComments =
        _int(raw, 'numComments') ?? _int(raw, 'num_comments') ?? 0;
    final createdUtc = _int(raw, 'createdUtc') ?? _int(raw, 'created_utc') ?? 0;
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
      vote: _parseVote(raw['likes']),
      isNsfw: _bool(raw, 'over_18') ?? _bool(raw, 'over18') ?? false,
      isSpoiler: _bool(raw, 'spoiler') ?? false,
      isSaved: _bool(raw, 'saved') ?? false,
      isStickied: _bool(raw, 'stickied') ?? false,
      isLocked: _bool(raw, 'locked') ?? false,
      awardCount: _int(raw, 'totalAwardsReceived') ??
          _int(raw, 'total_awards_received') ??
          0,
      createdAt: createdUtc > 0
          ? DateTime.fromMillisecondsSinceEpoch(createdUtc * 1000)
          : DateTime.now(),
      permalink: permalink,
      upvoteRatio: _double(raw, 'upvoteRatio') ?? _double(raw, 'upvote_ratio'),
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
    final score = _int(raw, 'score') ?? 0;
    final depth = _int(raw, 'depth') ?? 0;
    final createdUtc = _int(raw, 'createdUtc') ?? _int(raw, 'created_utc') ?? 0;
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
      vote: _parseVote(raw['likes']),
      isSaved: _bool(raw, 'saved') ?? false,
      isSubmitter:
          _bool(raw, 'isSubmitter') ?? _bool(raw, 'is_submitter') ?? false,
      isModerator: (raw['distinguished'] as String?) == 'moderator',
      isAdmin: (raw['distinguished'] as String?) == 'admin',
      isApprovedSubmitter: (raw['distinguished'] as String?) == 'special',
      isControversial: (_int(raw, 'controversiality') ?? 0) > 0,
      isScoreHidden:
          _bool(raw, 'scoreHidden') ?? _bool(raw, 'score_hidden') ?? false,
      isStickied: _bool(raw, 'stickied') ?? false,
      awardCount: _int(raw, 'totalAwardsReceived') ??
          _int(raw, 'total_awards_received') ??
          0,
      createdAt: createdUtc > 0
          ? DateTime.fromMillisecondsSinceEpoch(createdUtc * 1000)
          : DateTime.now(),
      postId: linkId,
      parentId: parentId,
      depth: depth,
      replies: replies,
      isCollapsed: _bool(raw, 'collapsed') ?? false,
      subreddit: raw['subreddit'] as String?,
      linkTitle: raw['linkTitle'] as String? ?? raw['link_title'] as String?,
      linkPermalink:
          raw['linkPermalink'] as String? ?? raw['link_permalink'] as String?,
    );
  }

  Map<String, dynamic> _pageProps(Map<String, dynamic> extracted) {
    final props = extracted['props'] as Map<String, dynamic>?;
    if (props == null) return extracted;
    return props['pageProps'] as Map<String, dynamic>? ?? extracted;
  }

  PostType _inferType(Map<String, dynamic> raw) {
    final postHint = raw['postHint'] as String? ?? raw['post_hint'] as String?;
    final isGallery = _bool(raw, 'isGallery') ?? _bool(raw, 'is_gallery');
    final isSelf = _bool(raw, 'isSelf') ?? _bool(raw, 'is_self');

    if (postHint == 'image') return PostType.image;
    if (postHint == 'hosted:video') return PostType.video;
    if (postHint == 'rich:video') return PostType.video;
    if (isGallery == true) return PostType.gallery;
    if (isSelf == true) return PostType.self_;
    return PostType.link;
  }

  VoteDirection _parseVote(dynamic likes) {
    if (likes == true) return VoteDirection.upvote;
    if (likes == false) return VoteDirection.downvote;
    return VoteDirection.none;
  }

  int? _int(Map<String, dynamic> map, String key) => map[key] as int?;
  double? _double(Map<String, dynamic> map, String key) =>
      (map[key] as num?)?.toDouble();
  bool? _bool(Map<String, dynamic> map, String key) => map[key] as bool?;
}
