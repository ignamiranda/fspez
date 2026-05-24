import 'dart:convert';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../domain/models/session_cookie.dart';
import 'reddit_client.dart';
import 'cdp_cookie_provider.dart';
import 'session_store.dart';

class AuthAcquirer {
  final RedditClient _redditClient;

  AuthAcquirer({required RedditClient redditClient})
      : _redditClient = redditClient;

  Future<SessionCookie?> acquire(
    InAppWebViewController controller, {
    int maxAttempts = 10,
    Duration interval = const Duration(milliseconds: 500),
  }) async {
    final provider = CdpCookieProvider(controller);
    final store = SessionStore(cookieProvider: provider);
    final cookie = await store.acquire(maxAttempts: maxAttempts, interval: interval);
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

  Future<String> extractUsername(
    SessionCookie cookie, {
    InAppWebViewController? controller,
  }) async {
    if (controller != null) {
      try {
        final js = await controller.evaluateJavascript(source: '''
          (function() {
            var el = document.querySelector('shreddit-app');
            if (el && el.getAttribute('username')) return el.getAttribute('username');
            var meta = document.querySelector('meta[name="twitter:data1"]');
            if (meta && meta.getAttribute('value')) return meta.getAttribute('value');
            var links = document.querySelectorAll('a[href*="/user/"]');
            for (var i = 0; i < links.length; i++) {
              var m = links[i].href.match(/\\/user\\/([^\\/?#]+)/);
              if (m && m[1] && !m[1].startsWith('t2_') && m[1].length < 25) {
                if (links[i].closest('header, [class*="Header"], [class*="navbar"], [class*="top"]'))
                  return m[1];
              }
            }
            return null;
          })()
        ''');
        if (js is String && js.isNotEmpty && js != 'null') {
          return js;
        }
      } catch (_) {}
    }

    try {
      final me = await _redditClient.get('/api/me', sessionCookie: cookie);
      final data = me['data'] as Map<String, dynamic>?;
      final name = data?['name'] as String?;
      if (name != null && name.isNotEmpty) {
        return name;
      }
    } catch (_) {}

    return _extractUsernameFromCookie(cookie.value);
  }

  String _extractUsernameFromCookie(String cookieValue) {
    try {
      final decoded = Uri.decodeComponent(cookieValue);
      final sepPatterns = [':', '%3A', ',', '|'];
      for (final sep in sepPatterns) {
        final parts = decoded.split(sep);
        for (final part in parts) {
          final trimmed = part.trim();
          if (trimmed.isNotEmpty &&
              trimmed.length < 30 &&
              !RegExp(r'^t[0-9]+_').hasMatch(trimmed)) {
            return trimmed;
          }
        }
      }
      if (decoded.contains('.')) {
        final parts = decoded.split('.');
        if (parts.length >= 2) {
          try {
            final padded = base64Url.normalize(parts[1]);
            final json = utf8.decode(base64Url.decode(padded));
            final map = jsonDecode(json) as Map;
            for (final key in ['sub', 'name', 'username', 'id']) {
              if (map.containsKey(key) &&
                  map[key] is String &&
                  (map[key] as String).isNotEmpty) {
                return map[key] as String;
              }
            }
          } catch (_) {}
        }
      }
      return 'user_${cookieValue.hashCode.abs().toString().substring(0, 6)}';
    } catch (_) {
      return 'unknown';
    }
  }
}
