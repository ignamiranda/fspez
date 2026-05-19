import '../domain/models/session_cookie.dart';

abstract class CookieProvider {
  Future<String?> getRedditSessionValue();
  Future<String?> getCookieString();
}

class SessionStore {
  final CookieProvider _cookieProvider;

  SessionStore({
    required CookieProvider cookieProvider,
  }) : _cookieProvider = cookieProvider;

  Future<SessionCookie?> acquire({
    int maxAttempts = 10,
    Duration interval = const Duration(milliseconds: 500),
  }) async {
    for (var i = 0; i < maxAttempts; i++) {
      final value = await _cookieProvider.getRedditSessionValue();
      if (value != null) {
        final raw = await _cookieProvider.getCookieString();
        return SessionCookie.fromValue(value, rawCookie: raw);
      }
      if (i < maxAttempts - 1) {
        await Future.delayed(interval);
      }
    }
    return null;
  }
}
