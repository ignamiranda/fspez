import '../domain/models/comment.dart';
import '../domain/models/user_flair.dart';
import 'api_responses/api_responses.dart';
import 'parsers/shared_parsers.dart';

class CommentParser {
  List<Comment> parseComments(List<dynamic> children) {
    return children
        .whereType<Map<String, dynamic>>()
        .where((child) => child['kind'] == 't1')
        .map((child) => _toDomain(
            ApiComment.fromJson(child['data'] as Map<String, dynamic>)))
        .toList();
  }

  Comment _toDomain(ApiComment api) {
    return Comment(
      id: api.id,
      body: api.body,
      author: api.author,
      score: api.score,
      vote: parseVoteDirection(api.likes),
      isSaved: api.saved,
      isSubmitter: api.isSubmitter,
      isModerator: api.distinguished == 'moderator',
      isStickied: api.stickied,
      awardCount: api.awardCount,
      createdAt: DateTime.fromMillisecondsSinceEpoch(api.createdUtc * 1000),
      postId: api.linkId,
      parentId: api.parentId,
      depth: api.depth,
      replies: api.replies.map(_toDomain).toList(),
      isCollapsed: api.collapsed,
      authorFlair: UserFlair.fromApi(
        text: api.authorFlairText,
        richtext: api.authorFlairRichtext,
        backgroundColor: api.authorFlairBackgroundColor,
        textColor: api.authorFlairTextColor,
      ),
      subreddit: api.commentSubreddit,
      linkTitle: api.linkTitle,
      linkPermalink: api.linkPermalink,
    );
  }
}
