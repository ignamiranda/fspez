import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../domain/models/account.dart';
import '../../data/auth_providers.dart';
import '../../data/reddit_client_provider.dart';
import '../../data/auth_acquirer.dart';

class AuthWebViewScreen extends ConsumerStatefulWidget {
  const AuthWebViewScreen({super.key});

  @override
  ConsumerState<AuthWebViewScreen> createState() => _AuthWebViewScreenState();
}

class _AuthWebViewScreenState extends ConsumerState<AuthWebViewScreen> {
  InAppWebViewController? _controller;
  bool _done = false;
  bool _loading = false;

  Future<void> _acquireSession() async {
    final c = _controller;
    if (c == null || _done) return;

    setState(() => _loading = true);
    try {
      final acquirer = AuthAcquirer(
        redditClient: ref.read(redditClientProvider),
      );

      final cookie = await acquirer.acquire(c,
          maxAttempts: 20, interval: const Duration(milliseconds: 500));
      if (cookie == null || _done) return;

      _done = true;
      final username = await acquirer.extractUsername(cookie, controller: c);

      final account = Account(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: username,
        sessionCookie: cookie,
      );

      await ref.read(activeAccountProvider.notifier).addAccount(account);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logged in as $username')),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Account')),
      body: Stack(
        children: [
          InAppWebView(
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
          if (_loading)
            const Positioned(
              left: 0,
              right: 0,
              top: 8,
              child: Center(
                child: Card(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Detecting session...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _acquireSession,
        icon: const Icon(Icons.refresh),
        label: const Text('Check Session'),
      ),
    );
  }
}
