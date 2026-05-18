import 'dart:convert';
import '../domain/models/session_cookie.dart';

SessionCookie? extractCookieFromJs(String documentCookie) {
  if (!documentCookie.contains('reddit_session')) return null;

  final match = RegExp(r'reddit_session=([^;]+)').firstMatch(documentCookie);
  if (match == null) return null;

  return SessionCookie(
    value: match.group(1)!,
    expiresAt: DateTime.now().add(const Duration(days: 365)),
  );
}

String extractUsername(String cookieValue) {
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
            if (map.containsKey(key) && map[key] is String && (map[key] as String).isNotEmpty) {
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
