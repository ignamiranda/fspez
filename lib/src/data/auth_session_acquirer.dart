import '../domain/models/session_cookie.dart';
import 'reddit_client.dart';
import 'session_store.dart';

class AuthSessionAcquirer {
  AuthSessionAcquirer({
    required CookieProvider cookieProvider,
    required RedditClient redditClient,
  })  : _cookieProvider = cookieProvider,
        _redditClient = redditClient;

  final CookieProvider _cookieProvider;
  final RedditClient _redditClient;

  Future<SessionCookie?> acquire() async {
    final store = SessionStore(cookieProvider: _cookieProvider);
    final cookie = await store.acquire();
    if (cookie == null) return null;

    final modhash = await _fetchModhash(cookie);
    return SessionCookie(
      value: cookie.value,
      expiresAt: cookie.expiresAt,
      rawCookie: cookie.rawCookie,
      modhash: modhash ?? cookie.modhash,
    );
  }

  Future<String?> _fetchModhash(SessionCookie cookie) async {
    try {
      final me = await _redditClient.get('/api/me', sessionCookie: cookie);
      final data = me['data'] as Map<String, dynamic>?;
      final mh = data?['modhash'] as String?;
      if (mh != null && mh.isNotEmpty) return mh;
    } catch (_) {}
    return null;
  }
}
