import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../domain/models/account.dart';
import '../../domain/models/session_cookie.dart';
import '../../data/providers.dart';
import '../../data/auth_service.dart';

class AuthWebViewScreen extends ConsumerStatefulWidget {
  const AuthWebViewScreen({super.key});

  @override
  ConsumerState<AuthWebViewScreen> createState() => _AuthWebViewScreenState();
}

class _AuthWebViewScreenState extends ConsumerState<AuthWebViewScreen> {
  InAppWebViewController? _controller;
  bool _done = false;

  Future<void> _pollCookie() async {
    final c = _controller;
    if (c == null) return;

    for (var i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (_done) return;

      try {
        final r = await c.callDevToolsProtocolMethod(
          methodName: 'Network.getCookies',
          parameters: {},
        );
        if (r is! Map || r['cookies'] is! List) continue;
        for (final ck in r['cookies'] as List) {
          if (ck is Map && ck['name'] == 'reddit_session') {
            await _login(ck['value'] as String);
            return;
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _login(String cookieValue) async {
    if (_done) return;
    _done = true;

    String? username;

    try {
      final js = await _controller?.evaluateJavascript(source: '''
        (function() {
          var s = window.__r && window.__r.user && window.__r.user.name;
          if (s) return s;
          var el = document.querySelector('shreddit-app');
          if (el && el.getAttribute('username')) return el.getAttribute('username');
          var links = document.querySelectorAll('a[href*="/user/"]');
          for (var i = 0; i < links.length; i++) {
            var m = links[i].href.match(/\\/user\\/([^\\/?#]+)/);
            if (m && m[1] && !m[1].startsWith('t2_') && m[1].length < 25) {
              if (links[i].closest('header, [class*="Header"], [class*="navbar"], [class*="top"]'))
                return m[1];
            }
          }
          for (var i = 0; i < links.length; i++) {
            var m = links[i].href.match(/\\/user\\/([^\\/?#]+)/);
            if (m && m[1] && !m[1].startsWith('t2_') && m[1].length < 25) {
              var txt = (links[i].textContent || '').trim();
              if (txt && txt.length < 25 && txt === m[1]) return txt;
            }
          }
          return null;
        })()
      ''');
      if (js is String && js.isNotEmpty && js != 'null') {
        username = js;
      }
    } catch (_) {}

    username ??= extractUsername(cookieValue);

    final account = Account(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: username,
      sessionCookie: SessionCookie(
        value: cookieValue,
        expiresAt: DateTime.now().add(const Duration(days: 365)),
      ),
      isDefault: true,
    );

    await ref.read(activeAccountProvider.notifier).addAccount(account);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Logged in as $username')),
    );
    Navigator.of(context).pop();
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
          _pollCookie();
        },
      ),
    );
  }
}
