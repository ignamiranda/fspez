import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../domain/models/account.dart';
import '../../domain/models/session_cookie.dart';
import '../../data/providers.dart';
import '../../data/session_store.dart';
import '../../data/cookie_parser.dart';

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

    final provider = _CdpCookieProvider(c);
    final store = SessionStore(cookieProvider: provider);
    final cookie = await store.acquire();
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

    return CookieParser().extractUsername(cookie.value);
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

class _CdpCookieProvider implements CookieProvider {
  final InAppWebViewController _controller;

  _CdpCookieProvider(this._controller);

  @override
  Future<String?> getRedditSessionValue() async {
    try {
      final r = await _controller.callDevToolsProtocolMethod(
        methodName: 'Network.getCookies',
        parameters: {},
      );
      if (r is! Map || r['cookies'] is! List) return null;
      for (final ck in r['cookies'] as List) {
        if (ck is Map && ck['name'] == 'reddit_session') {
          return ck['value'] as String;
        }
      }
    } catch (_) {}
    return null;
  }
}
