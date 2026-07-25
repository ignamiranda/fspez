import 'package:flutter/foundation.dart';
import '../domain/models/session_cookie.dart';
import 'html_parser_utils.dart';
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
    final username = extractUsernameFromHtml(html);
    if (username != null) {
      return SessionInfo(
        username: username,
        modhash: extractModhashFromHtml(html),
      );
    }
  } catch (e) {
    debugPrint('fetchSessionInfo HTML failed: $e');
  }

  return const SessionInfo(username: 'unknown', modhash: null);
}
