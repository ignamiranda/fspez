import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../domain/models/account.dart';
import '../../data/auth_providers.dart';
import '../../data/reddit_client_provider.dart';
import '../../data/auth_acquirer.dart';
import '../../data/cdp_cookie_provider.dart';
import '../../data/session_acquirer.dart';

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
    if (c == null || _done || _loading) return;

    setState(() => _loading = true);
    try {
      final provider = CdpCookieProvider(c);
      final acquirer = AuthAcquirer(
        redditClient: ref.read(redditClientProvider),
      );

      final store = SessionAcquirer(cookieProvider: provider);
      final cookie = await acquirer.acquire(store,
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
    } catch (e) {
      debugPrint('SessionAcquisition failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign-in failed: ${_shortError(e)}'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(label: 'Retry', onPressed: _acquireSession),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _shortError(Object e) {
    final s = e.toString();
    // Keep socket/host messages readable but not too technical
    if (s.contains('SocketException')) {
      return 'Could not connect to Reddit. Check your network connection.';
    }
    if (s.length > 100) {
      return '${s.substring(0, 100)}...';
    }
    return s;
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
              mixedContentMode: MixedContentMode.MIXED_CONTENT_NEVER_ALLOW,
            ),
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final url = navigationAction.request.url;
              if (url != null && url.scheme == 'https') {
                return NavigationActionPolicy.ALLOW;
              }
              return NavigationActionPolicy.CANCEL;
            },
            onWebViewCreated: (controller) {
              _controller = controller;
            },
            onLoadStop: (controller, url) async {
              if (_done || url == null) return;
              if (url.host.endsWith('.reddit.com') ||
                  url.host == 'reddit.com') {
                final s = url.toString();
                if (s.contains('/login') || s.contains('/accounts/')) return;
                _acquireSession();
              }
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
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
