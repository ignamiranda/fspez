import '../domain/models/comment.dart';
import '../domain/models/post.dart';
import '../domain/models/subreddit.dart';
import '../domain/models/session_cookie.dart';
import '../domain/enums/comment_sort.dart';
import 'reddit_client.dart';
import 'api_responses/api_responses.dart';
import 'reddit_award_html_parser.dart';
import 'message_client.dart';
import 'parsers/shared_parsers.dart';

class PostDetail {
  final Post post;
  final List<Comment> comments;

  const PostDetail({required this.post, required this.comments});
}

class CommentRepository {
  final RedditClient _client;
  final MessageClient _messageClient;

  CommentRepository(this._client, this._messageClient);

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
        .map((child) => commentFromApiData(child['data'] as Map<String, dynamic>))
        .toList();
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
    await _messageClient.comment(
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
    await _messageClient.comment(
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
