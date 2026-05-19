import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../domain/models/account.dart';
import '../../data/providers.dart';
import '../../data/auth_acquirer.dart';

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

    final acquirer = AuthAcquirer(
      redditClient: ref.read(redditClientProvider),
    );

    final cookie = await acquirer.acquire(c);
    if (cookie == null || _done) return;

    _done = true;
    final username = await acquirer.extractUsername(cookie, controller: c);

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
