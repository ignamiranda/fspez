import '../../domain/enums/vote_direction.dart';
import '../../domain/models/post.dart';
import '../api_responses/api_comment.dart';
import '../../domain/models/comment.dart';
import '../../domain/models/user_flair.dart';

VoteDirection parseVoteDirection(dynamic likes) {
  if (likes == true) return VoteDirection.upvote;
  if (likes == false) return VoteDirection.downvote;
  return VoteDirection.none;
}

PostType postTypeFromMap(Map<String, dynamic> data) {
  final hint = data['post_hint'] as String?;
  if (hint == 'image') return PostType.image;
  if (hint == 'link') return PostType.link;
  if (hint == 'hosted:video') return PostType.video;
  if (hint == 'rich:video') return PostType.video;
  if (data['is_gallery'] == true) return PostType.gallery;
  if (data['is_self'] == true) return PostType.self_;
  if (data['crosspost_parent'] != null) return PostType.crosspost;
  return PostType.link;
}

/// Canonical ApiComment → Comment mapper.
/// All production code should go through this.
Comment commentFromApi(ApiComment api) {
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
    replies: api.replies.map(commentFromApi).toList(),
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

/// Convenience wrapper for callers that have raw JSON data.
Comment commentFromApiData(Map<String, dynamic> data) {
  return commentFromApi(ApiComment.fromJson(data));
}
