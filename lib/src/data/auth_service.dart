import 'dart:async';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import '../domain/models/session_cookie.dart';

class AuthService {
  final FlutterWebviewPlugin _webviewPlugin = FlutterWebviewPlugin();
  final _cookieCompleter = Completer<SessionCookie>();

  static const _loginUrl = 'https://www.reddit.com/login';

  Stream<AuthState> get authState => _authStateController.stream;
  final _authStateController = StreamController<AuthState>.broadcast();

  Future<SessionCookie> login() async {
    _authStateController.add(AuthState.inProgress);

    _webviewPlugin.launch(
      _loginUrl,
      withJavascript: true,
      withLocalStorage: true,
      clearCookies: true,
      hidden: false,
    );

    _webviewPlugin.onUrlChanged.listen((String url) {
      if (url.contains('reddit.com') && !url.contains('/login')) {
        _extractCookie();
      }
    });

    return _cookieCompleter.future;
  }

  Future<void> _extractCookie() async {
    try {
      final cookies = await _webviewPlugin.evalJavascript(
        'document.cookie',
      );

      if (cookies is String && cookies.contains('reddit_session')) {
        final sessionMatch = RegExp(r'reddit_session=([^;]+)').firstMatch(cookies);
        if (sessionMatch != null) {
          final cookieValue = sessionMatch.group(1)!;

          await _webviewPlugin.close();

          final cookie = SessionCookie(
            value: cookieValue,
            expiresAt: DateTime.now().add(const Duration(days: 365)),
          );

          _cookieCompleter.complete(cookie);
          _authStateController.add(AuthState.authenticated);
          return;
        }
      }
    } catch (e) {
      _cookieCompleter.completeError(AuthException('Failed to extract cookie: $e'));
      _authStateController.add(AuthState.error);
    }
  }

  Future<void> logout() async {
    await _webviewPlugin.close();
    _authStateController.add(AuthState.unauthenticated);
  }

  void dispose() {
    _webviewPlugin.dispose();
    _authStateController.close();
  }
}

enum AuthState { unauthenticated, inProgress, authenticated, error }

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
