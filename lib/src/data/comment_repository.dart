import '../domain/models/comment.dart';
import '../domain/models/post.dart';
import '../domain/models/subreddit.dart';
import '../domain/models/user_flair.dart';
import '../domain/models/session_cookie.dart';
import '../domain/enums/comment_sort.dart';
import '../domain/enums/vote_direction.dart';
import 'reddit_client.dart';
import 'api_responses.dart';
import 'reddit_award_html_parser.dart';

class PostDetail {
  final Post post;
  final List<Comment> comments;

  const PostDetail({required this.post, required this.comments});
}

class CommentRepository {
  final RedditClient _client;

  CommentRepository(this._client);

  Future<PostDetail> fetchComments(
    String subreddit,
    String postId, {
    CommentSort? sort,
    SessionCookie? sessionCookie,
  }) async {
    final raw = await _client.getRaw(
      '/r/$subreddit/comments/$postId',
      queryParams: sort != null ? {'sort': sort.queryValue} : null,
      sessionCookie: sessionCookie,
    );

    final items = raw as List<dynamic>;

    ApiPost? apiPost;
    if (items.isNotEmpty) {
      final listing = items[0] as Map<String, dynamic>;
      final children = (listing['data'] as Map<String, dynamic>)['children']
          as List<dynamic>;
      for (final child in children) {
        final childMap = child as Map<String, dynamic>;
        if (childMap['kind'] == 't3') {
          apiPost = ApiPost.fromJson(childMap['data'] as Map<String, dynamic>);
        }
      }
    }

    final post = apiPost?.toDomain() ??
        Post(
          id: postId,
          title: '',
          author: '[deleted]',
          subreddit: Subreddit(id: '', name: subreddit),
          createdAt: DateTime.now(),
          permalink: '',
          type: PostType.self_,
        );

    final commentsListing =
        items.length > 1 ? items[1] as Map<String, dynamic> : null;
    final commentsChildren = commentsListing != null
        ? (commentsListing['data'] as Map<String, dynamic>)['children']
            as List<dynamic>
        : <dynamic>[];

    final comments = _parseComments(commentsChildren);

    try {
      final mainHtml = await _client.getHtml(
        '/r/$subreddit/comments/$postId',
        queryParams: sort != null ? {'sort': sort.queryValue} : null,
        sessionCookie: sessionCookie,
      );

      final awardCounts = <String, int>{}
        ..addAll(RedditAwardHtmlParser.parseAwardCounts(mainHtml));

      final partialPath =
          RedditAwardHtmlParser.extractCommentsPartialPath(mainHtml);
      if (partialPath != null) {
        final partialUri = Uri.parse(partialPath);
        final partialHtml = await _client.getHtml(
          partialUri.path,
          queryParams: partialUri.queryParameters.isEmpty
              ? null
              : partialUri.queryParameters,
          sessionCookie: sessionCookie,
        );
        awardCounts.addAll(RedditAwardHtmlParser.parseAwardCounts(partialHtml));
      }

      if (awardCounts.isNotEmpty) {
        return PostDetail(
          post: post.copyWith(
            awardCount: awardCounts[post.fullname] ?? post.awardCount,
          ),
          comments: comments
              .map((comment) => _applyAwards(comment, awardCounts))
              .toList(),
        );
      }
    } catch (_) {
      // Keep the JSON-derived detail when HTML award extraction fails.
    }

    return PostDetail(post: post, comments: comments);
  }

  List<Comment> _parseComments(List<dynamic> children) {
    return children
        .whereType<Map<String, dynamic>>()
        .where((child) => child['kind'] == 't1')
        .map((child) => _commentFromApi(
            ApiComment.fromJson(child['data'] as Map<String, dynamic>)))
        .toList();
  }

  Comment _commentFromApi(ApiComment api) {
    final vote = api.likes == true
        ? VoteDirection.upvote
        : api.likes == false
            ? VoteDirection.downvote
            : VoteDirection.none;
    return Comment(
      id: api.id,
      body: api.body,
      author: api.author,
      score: api.score,
      vote: vote,
      isSaved: api.saved,
      isSubmitter: api.isSubmitter,
      isModerator: api.distinguished == 'moderator',
      isStickied: api.stickied,
      awardCount: api.awardCount,
      createdAt: DateTime.fromMillisecondsSinceEpoch(api.createdUtc * 1000),
      postId: api.linkId,
      parentId: api.parentId,
      depth: api.depth,
      replies: api.replies.map(_commentFromApi).toList(),
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

  Comment _applyAwards(Comment comment, Map<String, int> awardCounts) {
    return comment.copyWith(
      awardCount: awardCounts[comment.fullname] ?? comment.awardCount,
      replies: comment.replies
          .map((reply) => _applyAwards(reply, awardCounts))
          .toList(),
    );
  }

  Future<void> reply({
    required String thingId,
    required String text,
    required SessionCookie sessionCookie,
  }) async {
    await _client.comment(
      fields: {
        'thing_id': thingId,
        'text': text,
        'uh': sessionCookie.modhash ?? '',
      },
      sessionCookie: sessionCookie,
    );
  }

  Future<void> edit({
    required String thingId,
    required String text,
    required SessionCookie sessionCookie,
  }) async {
    await _client.comment(
      fields: {
        'thing_id': thingId,
        'text': text,
        'uh': sessionCookie.modhash ?? '',
        'm': 'edit',
      },
      sessionCookie: sessionCookie,
    );
  }
}
