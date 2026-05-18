import '../domain/models/comment.dart';
import '../domain/models/post.dart';
import '../domain/models/subreddit.dart';
import '../domain/models/session_cookie.dart';
import 'reddit_client.dart';
import 'comment_parser.dart';
import 'feed_parser.dart';

class PostDetail {
  final Post post;
  final List<Comment> comments;

  const PostDetail({required this.post, required this.comments});
}

class CommentRepository {
  final RedditClient _client;
  final CommentParser _parser;

  CommentRepository(this._client, {CommentParser? parser})
      : _parser = parser ?? CommentParser();

  Future<PostDetail> fetchComments(
    String subreddit,
    String postId, {
    SessionCookie? sessionCookie,
  }) async {
    final raw = await _client.getRaw(
      '/r/$subreddit/comments/$postId',
      sessionCookie: sessionCookie,
    );

    final items = raw as List<dynamic>;
    final feedParser = FeedParser();

    final postListing =
        items.isNotEmpty ? items[0] as Map<String, dynamic> : null;
    final postChildren = postListing != null
        ? (postListing['data'] as Map<String, dynamic>)['children']
            as List<dynamic>
        : <dynamic>[];

    Post? post;
    for (final child in postChildren) {
      final childMap = child as Map<String, dynamic>;
      if (childMap['kind'] == 't3') {
        post = feedParser.parsePost(
            childMap['data'] as Map<String, dynamic>);
      }
    }

    final commentsListing = items.length > 1
        ? items[1] as Map<String, dynamic>
        : null;
    final commentsChildren = commentsListing != null
        ? (commentsListing['data'] as Map<String, dynamic>)['children']
            as List<dynamic>
        : <dynamic>[];
    final comments = _parser.parseComments(commentsChildren);

    return PostDetail(
      post: post ??
          Post(
            id: postId,
            title: '',
            author: '[deleted]',
            subreddit: Subreddit(id: '', name: subreddit),
            createdAt: DateTime.now(),
            permalink: '',
            type: PostType.self_,
          ),
      comments: comments,
    );
  }
}
