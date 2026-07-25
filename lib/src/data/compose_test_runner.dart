import 'dart:io';

import 'package:flutter/foundation.dart';
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
    } catch (e) {
      debugPrint('ComposeTestRunner._log failed: $e');
    }
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
      final html = await _client.getHtml('/', sessionCookie: cookie);
      final modhash = _extractModhash(html);
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
}
