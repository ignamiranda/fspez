import '../domain/models/session_cookie.dart';
import 'reddit_client.dart';

class VoteRepository {
  final RedditClient _client;

  VoteRepository(this._client);

  Future<void> vote(
    String fullname,
    int direction, {
    SessionCookie? sessionCookie,
  }) async {
    await _client.postForm('/api/vote',
        fields: {'id': fullname, 'dir': direction.toString()},
        sessionCookie: sessionCookie);
  }
}
