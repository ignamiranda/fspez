import '../domain/models/session_cookie.dart';
import 'cookie_parser.dart';

abstract class CookieProvider {
  Future<String?> getRedditSessionValue();
}

class SessionStore {
  final CookieProvider _cookieProvider;
  final CookieParser _cookieParser;

  SessionStore({
    required CookieProvider cookieProvider,
    CookieParser? cookieParser,
  })  : _cookieProvider = cookieProvider,
        _cookieParser = cookieParser ?? CookieParser();

  Future<SessionCookie?> acquire({
    int maxAttempts = 10,
    Duration interval = const Duration(milliseconds: 500),
  }) async {
    for (var i = 0; i < maxAttempts; i++) {
      final value = await _cookieProvider.getRedditSessionValue();
      if (value != null) {
        return _cookieParser.fromValue(value);
      }
      if (i < maxAttempts - 1) {
        await Future.delayed(interval);
      }
    }
    return null;
  }
}
