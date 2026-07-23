import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../domain/models/session_cookie.dart';
import 'reddit_client.dart';
import 'session_acquirer.dart';
import 'session_info.dart';
import 'username_extractor.dart';

class AuthAcquirer {
  final RedditClient _redditClient;
  final UsernameExtractor _usernameExtractor;
  String? _cachedUsername;

  AuthAcquirer({required RedditClient redditClient})
      : _redditClient = redditClient,
        _usernameExtractor = UsernameExtractor(redditClient: redditClient);

  Future<SessionCookie?> acquire(
    SessionAcquirer acquirer, {
    int maxAttempts = 10,
    Duration interval = const Duration(milliseconds: 500),
  }) async {
    final cookie =
        await acquirer.acquire(maxAttempts: maxAttempts, interval: interval);
    if (cookie == null) return null;

    final info = await fetchSessionInfo(_redditClient, cookie);
    _cachedUsername = info.username;

    return SessionCookie(
      value: cookie.value,
      expiresAt: cookie.expiresAt,
      rawCookie: cookie.rawCookie,
      modhash: info.modhash ?? cookie.modhash,
    );
  }

  Future<String> extractUsername(
    SessionCookie cookie, {
    InAppWebViewController? controller,
  }) async {
    if (_cachedUsername != null) return _cachedUsername!;
    return _usernameExtractor.extract(cookie, controller: controller);
  }
}
