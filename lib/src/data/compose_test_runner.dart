import 'dart:io';

import '../domain/models/session_cookie.dart';
import 'http_transport.dart';
import 'message_client.dart';
import 'reddit_client.dart';

class ComposeTestRunner {
  final RedditClient _client;
  final MessageClient _messageClient;
  final File _logFile = File('${Directory.systemTemp.path}\\fspez-compose.log');

  ComposeTestRunner({RedditClient? redditClient, MessageClient? messageClient})
      : _client = redditClient ?? RedditClient(),
        _messageClient = messageClient ?? MessageClient(HttpTransport());

  Future<void> _log(String message) async {
    try {
      await _logFile.writeAsString(
        '[${DateTime.now().toIso8601String()}] TEST $message\n',
        mode: FileMode.append,
      );
    } catch (_) {}
  }

  Future<bool> run({required String sessionValue}) async {
    await _logFile.writeAsString('', mode: FileMode.write);

    try {
      await _log('start to=codenameawesome subject=test text=test');
      var cookie = SessionCookie.fromValue(
        sessionValue,
        rawCookie: 'reddit_session=$sessionValue',
      );

      cookie = await _ensureModhash(cookie);
      await _log(
          'cookie raw=${cookie.rawCookie != null} modhash=${cookie.modhash != null}');

      await _messageClient.compose(
        fields: {
          'to': 'codenameawesome',
          'subject': 'test',
          'text': 'test',
          'uh': cookie.modhash ?? '',
          'api_type': 'json',
        },
        sessionCookie: cookie,
      );
      await _log('compose success');
      return true;
    } catch (e) {
      await _log('compose error=$e');
      return false;
    } finally {
      _client.dispose();
    }
  }

  Future<SessionCookie> _ensureModhash(SessionCookie cookie) async {
    if (cookie.modhash != null && cookie.modhash!.isNotEmpty) {
      return cookie;
    }

    try {
      final me = await _client.get('/api/me', sessionCookie: cookie);
      final data = me['data'] as Map<String, dynamic>?;
      final modhash = data?['modhash'] as String?;
      if (modhash != null && modhash.isNotEmpty) {
        await _log('fetched modhash=true');
        return SessionCookie(
          value: cookie.value,
          expiresAt: cookie.expiresAt,
          rawCookie: cookie.rawCookie,
          modhash: modhash,
        );
      }
      await _log('fetched modhash=false');
    } catch (e) {
      await _log('fetch modhash error=$e');
    }

    return cookie;
  }
}
