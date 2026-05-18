import '../domain/models/subreddit.dart';
import '../domain/models/session_cookie.dart';
import 'reddit_client.dart';

class SubredditRepository {
  final RedditClient _client;

  SubredditRepository(this._client);

  Future<Subreddit> fetch(String subredditName,
      {SessionCookie? sessionCookie}) async {
    final data =
        await _client.get('/r/$subredditName/about', sessionCookie: sessionCookie);
    final about = data['data'] as Map<String, dynamic>;

    return Subreddit(
      id: about['id'] as String? ?? '',
      name: about['display_name'] as String? ?? subredditName,
      description: about['public_description'] as String?,
      subscriberCount: about['subscribers'] as int? ?? 0,
      isNsfw: about['over18'] as bool? ?? false,
      isSubscribed: about['user_is_subscriber'] as bool? ?? false,
      iconUrl: about['icon_img'] as String? ?? about['community_icon'] as String?,
      bannerUrl: about['banner_img'] as String? ?? about['banner_background_image'] as String?,
    );
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
