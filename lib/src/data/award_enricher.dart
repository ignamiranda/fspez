import '../domain/enums/comment_sort.dart';
import '../domain/models/session_cookie.dart';
import 'reddit_award_html_parser.dart';
import 'reddit_client.dart';

/// Seam for enriching comment/post award counts beyond what the JSON API
/// provides. The JSON API returns [ApiPost.awardCount] and
/// [ApiComment.awardCount] from the `total_awards_received` field, but Reddit's
/// new UI may expose additional awards via the HTML page that the JSON omits.
///
/// Two implementations exist:
///   [HtmlAwardEnricher] — scrapes the HTML page (current prod behavior).
///   [NoopAwardEnricher] — returns empty map (used in tests).
abstract class AwardEnricher {
  const AwardEnricher();

  Future<Map<String, int>> fetchAwards(
    String subreddit,
    String postId, {
    CommentSort? sort,
    SessionCookie? sessionCookie,
  });
}

/// Scrapes award counts from Reddit's shreddit HTML page and its
/// `faceplate-partial` comments fragment. May make up to 2 HTTP calls.
class HtmlAwardEnricher extends AwardEnricher {
  final RedditClient _client;

  const HtmlAwardEnricher(this._client);

  @override
  Future<Map<String, int>> fetchAwards(
    String subreddit,
    String postId, {
    CommentSort? sort,
    SessionCookie? sessionCookie,
  }) async {
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

    return awardCounts;
  }
}

/// No-op enricher used in tests and when award HTML scraping is not desired.
class NoopAwardEnricher extends AwardEnricher {
  const NoopAwardEnricher();

  @override
  Future<Map<String, int>> fetchAwards(
    String subreddit,
    String postId, {
    CommentSort? sort,
    SessionCookie? sessionCookie,
  }) async {
    return const {};
  }
}
