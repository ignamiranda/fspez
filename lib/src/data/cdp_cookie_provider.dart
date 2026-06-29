import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'session_acquirer.dart';

class CdpCookieProvider implements CookieProvider {
  final InAppWebViewController _controller;

  CdpCookieProvider(this._controller);

  @override
  Future<String?> getRedditSessionValue() async {
    final fromCookieManager = await _tryCookieManager();
    if (fromCookieManager != null) return fromCookieManager;

    final fromCdp = await _tryCdp();
    if (fromCdp != null) return fromCdp;

    return null;
  }

  Future<String?> _tryCookieManager() async {
    try {
      final cookies = await CookieManager.instance()
          .getCookies(url: WebUri('https://www.reddit.com'));
      for (final c in cookies) {
        if (c.name == 'reddit_session') return c.value;
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _tryCdp() async {
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
    final fromCookieManager = await _tryCookieManagerString();
    if (fromCookieManager != null) return fromCookieManager;

    final fromCdp = await _tryCdpString();
    if (fromCdp != null) return fromCdp;

    return null;
  }

  Future<String?> _tryCookieManagerString() async {
    try {
      final cookies = await CookieManager.instance()
          .getCookies(url: WebUri('https://www.reddit.com'));
      if (cookies.isEmpty) return null;
      return cookies.map((c) => '${c.name}=${c.value}').join('; ');
    } catch (_) {}
    return null;
  }

  Future<String?> _tryCdpString() async {
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
