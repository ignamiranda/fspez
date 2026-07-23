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
    final me = await client.get('/api/me', sessionCookie: cookie);
    final data = me['data'] as Map<String, dynamic>?;
    final name = data?['name'] as String? ?? 'unknown';
    final mh = data?['modhash'] as String?;
    return SessionInfo(
      username: name,
      modhash: (mh != null && mh.isNotEmpty) ? mh : null,
    );
  } catch (e) {
    debugPrint('fetchSessionInfo failed: $e');
    return const SessionInfo(username: 'unknown', modhash: null);
  }
}
