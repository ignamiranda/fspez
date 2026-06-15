import '../post_mapping.dart' as post_mapping;

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
