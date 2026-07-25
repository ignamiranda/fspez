import 'package:flutter/foundation.dart';
import '../domain/models/comment.dart';
import '../domain/models/post_detail.dart';
import '../domain/models/session_cookie.dart';
import '../domain/enums/comment_sort.dart';
import 'reddit_client.dart';
import 'award_enricher.dart';
import 'html_post_thread_parser.dart';
import 'message_client.dart';

class CommentRepository {
  final RedditClient _client;
  final MessageClient _messageClient;
  final AwardEnricher _awardEnricher;

  CommentRepository(
    this._client,
    this._messageClient,
    this._awardEnricher,
  );

  Future<PostDetail> fetchComments(
    String subreddit,
    String postId, {
    CommentSort? sort,
    SessionCookie? sessionCookie,
  }) async {
    final html = await _client.getHtml(
      '/r/$subreddit/comments/$postId',
      queryParams: sort != null ? {'sort': sort.queryValue} : null,
      sessionCookie: sessionCookie,
    );
    final parsed = HtmlPostThreadParser().parse(html);
    return await _enrichWithAwards(parsed, subreddit, postId,
        sort: sort, sessionCookie: sessionCookie);
  }

  Future<PostDetail> _enrichWithAwards(
    PostDetail detail,
    String subreddit,
    String postId, {
    CommentSort? sort,
    SessionCookie? sessionCookie,
  }) async {
    try {
      final awardCounts = await _awardEnricher.fetchAwards(
        subreddit,
        postId,
        sort: sort,
        sessionCookie: sessionCookie,
      );

      if (awardCounts.isNotEmpty) {
        return PostDetail(
          post: detail.post.copyWith(
            awardCount:
                awardCounts[detail.post.fullname] ?? detail.post.awardCount,
          ),
          comments: detail.comments
              .map((comment) => _applyAwards(comment, awardCounts))
              .toList(),
        );
      }
    } catch (e) {
      debugPrint('CommentRepository._applyAwards HTML parsing failed: $e');
    }

    return detail;
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
