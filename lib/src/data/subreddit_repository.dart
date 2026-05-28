import '../domain/models/subreddit.dart';
import '../domain/models/subreddit_rule.dart';
import '../domain/models/session_cookie.dart';
import 'reddit_client.dart';
import 'api_responses.dart';

class SubredditRepository {
  final RedditClient _client;

  SubredditRepository(this._client);

  Future<Subreddit> fetch(String subredditName,
      {SessionCookie? sessionCookie}) async {
    final data = await _client.get('/r/$subredditName/about',
        sessionCookie: sessionCookie);
    final api = ApiSubreddit.fromJson(data['data'] as Map<String, dynamic>);
    return api.toDomain(subredditName);
  }

  Future<List<SubredditRule>> fetchRules(
    String subredditName, {
    SessionCookie? sessionCookie,
  }) async {
    final data = await _client.get('/r/$subredditName/about/rules',
        sessionCookie: sessionCookie);
    return ApiSubredditRules.fromJson(data).toDomain();
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
