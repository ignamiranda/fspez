import '../domain/models/subreddit.dart';
import '../domain/models/subreddit_rule.dart';
import '../domain/models/session_cookie.dart';
import 'html_subreddit_parser.dart';
import 'reddit_client.dart';

class SubredditRepository {
  final RedditClient _client;

  SubredditRepository(this._client);

  Future<Subreddit> fetch(String subredditName,
      {SessionCookie? sessionCookie}) async {
    final html = await _client.getHtml(
      '/r/$subredditName/about',
      sessionCookie: sessionCookie,
    );
    return HtmlSubredditParser().parseInfo(html, subredditName);
  }

  Future<List<SubredditRule>> fetchRules(
    String subredditName, {
    SessionCookie? sessionCookie,
  }) async {
    final html = await _client.getHtml(
      '/r/$subredditName/about/rules',
      sessionCookie: sessionCookie,
    );
    return HtmlSubredditParser().parseRules(html);
  }

  Future<void> subscribe(String subredditName,
      {SessionCookie? sessionCookie}) async {
    await _client.post('/api/subscribe',
        body: {'sr_name': subredditName, 'action': 'sub'},
        sessionCookie: sessionCookie);
  }

  Future<void> unsubscribe(String subredditName,
      {SessionCookie? sessionCookie}) async {
    await _client.post('/api/subscribe',
        body: {'sr_name': subredditName, 'action': 'unsub'},
        sessionCookie: sessionCookie);
  }
}
