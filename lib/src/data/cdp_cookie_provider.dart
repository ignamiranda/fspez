import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'session_store.dart';

class CdpCookieProvider implements CookieProvider {
  final InAppWebViewController _controller;

  CdpCookieProvider(this._controller);

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

  @override
  Future<String?> getCookieString() async {
    try {
      final r = await _controller.callDevToolsProtocolMethod(
        methodName: 'Network.getCookies',
        parameters: {},
      );
      if (r is! Map || r['cookies'] is! List) return null;
      final cookies = (r['cookies'] as List).cast<Map>();
      return cookies.map((c) => '${c['name']}=${c['value']}').join('; ');
    } catch (_) {}
    return null;
  }
}
