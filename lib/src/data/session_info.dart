import 'package:flutter/foundation.dart';
import '../domain/models/session_cookie.dart';
import 'reddit_client.dart';

class SessionInfo {
  final String username;
  final String? modhash;

  const SessionInfo({required this.username, this.modhash});
}

Future<SessionInfo> fetchSessionInfo(
    RedditClient client, SessionCookie cookie) async {
  try {
    final html = await client.getHtml('/', sessionCookie: cookie);
    final username = _extractUsername(html);
    if (username != null) {
      return SessionInfo(
        username: username,
        modhash: _extractModhash(html),
      );
    }
  } catch (e) {
    debugPrint('fetchSessionInfo HTML failed: $e');
  }

  try {
    final me = await client.get('/api/me', sessionCookie: cookie);
    final data = me['data'] as Map<String, dynamic>?;
    final name = data?['name'] as String? ?? 'unknown';
    final mh = data?['modhash'] as String?;
    return SessionInfo(
      username: name,
      modhash: (mh != null && mh.isNotEmpty) ? mh : null,
    );
  } catch (e) {
    debugPrint('fetchSessionInfo JSON fallback failed: $e');
    return const SessionInfo(username: 'unknown', modhash: null);
  }
}

String? _extractUsername(String html) {
  final patterns = [
    RegExp(r'"loggedInUser"\s*:\s*"([^"]+)"'),
    RegExp(r'"user"\s*:\s*\{\s*"name"\s*:\s*"([^"]+)"'),
    RegExp(r'"username"\s*:\s*"([^"]+)"'),
    RegExp(r'<shreddit-app[^>]*username="([^"]+)"'),
  ];

  for (final pattern in patterns) {
    final match = pattern.firstMatch(html);
    if (match != null) {
      final name = match.group(1);
      if (name != null && name.isNotEmpty && name.length < 30) return name;
    }
  }

  return null;
}

String? _extractModhash(String html) {
  final patterns = [
    RegExp(r'"modhash"\s*:\s*"([^"]+)"'),
    RegExp(r'name="uh"\s+value="([^"]+)"'),
    RegExp(r'X-Modhash:\s*([a-z0-9]+)'),
  ];

  for (final pattern in patterns) {
    final match = pattern.firstMatch(html);
    if (match != null) {
      final hash = match.group(1);
      if (hash != null && hash.isNotEmpty) return hash;
    }
  }

  return null;
}
