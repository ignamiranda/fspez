import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../domain/models/session_cookie.dart';
import 'reddit_client.dart';
import 'cdp_cookie_provider.dart';
import 'session_store.dart';
import 'modhash_fetcher.dart';
import 'username_extractor.dart';

class AuthAcquirer {
  final ModhashFetcher _modhashFetcher;
  final UsernameExtractor _usernameExtractor;

  AuthAcquirer({required RedditClient redditClient})
      : _modhashFetcher = ModhashFetcher(redditClient: redditClient),
        _usernameExtractor = UsernameExtractor(redditClient: redditClient);

  Future<SessionCookie?> acquire(
    InAppWebViewController controller, {
    int maxAttempts = 10,
    Duration interval = const Duration(milliseconds: 500),
  }) async {
    final provider = CdpCookieProvider(controller);
    final store = SessionStore(cookieProvider: provider);
    final cookie = await store.acquire(maxAttempts: maxAttempts, interval: interval);
    if (cookie == null) return null;

    final modhash = await _modhashFetcher.fetch(cookie);
    return SessionCookie(
      value: cookie.value,
      expiresAt: cookie.expiresAt,
      rawCookie: cookie.rawCookie,
      modhash: modhash ?? cookie.modhash,
    );
  }

  Future<String> extractUsername(
    SessionCookie cookie, {
    InAppWebViewController? controller,
  }) async {
    return _usernameExtractor.extract(cookie, controller: controller);
  }
}
