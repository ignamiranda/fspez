import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../domain/models/account.dart';
import '../../domain/models/session_cookie.dart';
import '../../data/providers.dart';
import '../../data/auth_session_acquirer.dart';
import '../../data/cdp_cookie_provider.dart';

class AuthWebViewScreen extends ConsumerStatefulWidget {
  const AuthWebViewScreen({super.key});

  @override
  ConsumerState<AuthWebViewScreen> createState() => _AuthWebViewScreenState();
}

class _AuthWebViewScreenState extends ConsumerState<AuthWebViewScreen> {
  InAppWebViewController? _controller;
  bool _done = false;

  Future<void> _acquireSession() async {
    final c = _controller;
    if (c == null || _done) return;

    final acquirer = AuthSessionAcquirer(
      cookieProvider: CdpCookieProvider(c),
      redditClient: ref.read(redditClientProvider),
    );

    final cookie = await acquirer.acquire();
    if (cookie == null || _done) return;

    _done = true;
    final username = await _extractUsername(cookie);

    final account = Account(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: username,
      sessionCookie: cookie,
      isDefault: true,
    );

    await ref.read(activeAccountProvider.notifier).addAccount(account);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Logged in as $username')),
    );
    Navigator.of(context).pop();
  }

  Future<String> _extractUsername(SessionCookie cookie) async {
    try {
      final js = await _controller?.evaluateJavascript(source: '''
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

    try {
      final client = ref.read(redditClientProvider);
      final me = await client.get('/api/me', sessionCookie: cookie);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Account')),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri('https://www.reddit.com/login'),
        ),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
        ),
        onWebViewCreated: (controller) {
          _controller = controller;
        },
        onLoadStop: (controller, url) async {
          if (_done || url == null) return;
          final s = url.toString();
          if (s.contains('/login') || s.contains('/accounts/')) return;
          _acquireSession();
        },
      ),
    );
  }
}
