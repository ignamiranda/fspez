import '../domain/models/session_cookie.dart';
import 'reddit_client.dart';

class ModhashFetcher {
  final RedditClient _redditClient;

  ModhashFetcher({required RedditClient redditClient})
      : _redditClient = redditClient;

  Future<String?> fetch(SessionCookie cookie) async {
    try {
      final me = await _redditClient.get('/api/me', sessionCookie: cookie);
      final data = me['data'] as Map<String, dynamic>?;
      final mh = data?['modhash'] as String?;
      if (mh != null && mh.isNotEmpty) return mh;
    } catch (_) {}
    return null;
  }
}
