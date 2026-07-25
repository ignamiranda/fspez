import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/account.dart';
import 'auth_providers.dart';
import 'reddit_client.dart';
import 'reddit_client_provider.dart';

enum SessionHealthStatus { healthy, missingModhash, expired, unknown }

class SessionHealth {
  final SessionHealthStatus status;
  final String title;
  final String message;
  final String actionLabel;
  final String? newModhash;

  const SessionHealth._({
    required this.status,
    required this.title,
    required this.message,
    required this.actionLabel,
    this.newModhash,
  });

  bool get needsRecovery => status != SessionHealthStatus.healthy;

  static const healthy = SessionHealth._(
    status: SessionHealthStatus.healthy,
    title: 'Session healthy',
    message: 'This account is signed in and ready to use.',
    actionLabel: '',
  );

  static const missingModhash = SessionHealth._(
    status: SessionHealthStatus.missingModhash,
    title: 'Session needs refresh',
    message:
        'Reddit can read this session, but write actions may fail until you re-login.',
    actionLabel: 'Re-login',
  );

  static const expired = SessionHealth._(
    status: SessionHealthStatus.expired,
    title: 'Session expired',
    message:
        'Reddit rejected this account. Re-login or switch to another account.',
    actionLabel: 'Re-login',
  );

  static const unknown = SessionHealth._(
    status: SessionHealthStatus.unknown,
    title: 'Session needs attention',
    message:
        'fspez could not verify this account right now. Try re-login if actions keep failing.',
    actionLabel: 'Re-login',
  );
}

final sessionHealthProvider = FutureProvider<SessionHealth?>((ref) async {
  final account = ref.watch(activeAccountProvider);
  if (account == null) return null;

  return checkSessionHealth(
    ref.watch(redditClientProvider),
    account,
  );
});

Future<SessionHealth> checkSessionHealth(
  RedditClient redditClient,
  Account account,
) async {
  try {
    final html = await redditClient.getHtml(
      '/',
      sessionCookie: account.sessionCookie,
    );

    final username = _extractUsernameFromHtml(html);
    final modhash = _extractModhashFromHtml(html);

    if (username == null || username.isEmpty) {
      return SessionHealth.expired;
    }

    if (username != account.username) {
      return SessionHealth._(
        status: SessionHealthStatus.expired,
        title: 'Session username changed',
        message:
            'Reddit says this session belongs to $username, but fspez saved ${account.username}. Re-login to refresh it.',
        actionLabel: 'Re-login',
      );
    }

    if (account.sessionCookie.modhash == null) {
      if (modhash != null) {
        return SessionHealth._(
          status: SessionHealthStatus.healthy,
          title: 'Session healthy',
          message: '',
          actionLabel: '',
          newModhash: modhash,
        );
      }
      return SessionHealth.missingModhash;
    }

    return SessionHealth.healthy;
  } on RedditApiException catch (error) {
    if (error.statusCode == 401 || error.statusCode == 403) {
      return SessionHealth.expired;
    }
    return SessionHealth.unknown;
  } catch (e) {
    debugPrint('SessionHealth check failed: $e');
    return SessionHealth.unknown;
  }
}

String? _extractUsernameFromHtml(String html) {
  final usernamePatterns = [
    RegExp(r'"loggedInUser"\s*:\s*"([^"]+)"'),
    RegExp(r'"user"\s*:\s*\{\s*"name"\s*:\s*"([^"]+)"'),
    RegExp(r'"username"\s*:\s*"([^"]+)"'),
    RegExp(r'<shreddit-app[^>]*username="([^"]+)"'),
  ];

  for (final pattern in usernamePatterns) {
    final match = pattern.firstMatch(html);
    if (match != null) {
      final name = match.group(1);
      if (name != null && name.isNotEmpty && name.length < 30) return name;
    }
  }

  return null;
}

String? _extractModhashFromHtml(String html) {
  final modhashPatterns = [
    RegExp(r'"modhash"\s*:\s*"([^"]+)"'),
    RegExp(r'name="uh"\s+value="([^"]+)"'),
    RegExp(r'X-Modhash:\s*([a-z0-9]+)'),
  ];

  for (final pattern in modhashPatterns) {
    final match = pattern.firstMatch(html);
    if (match != null) {
      final hash = match.group(1);
      if (hash != null && hash.isNotEmpty) return hash;
    }
  }

  return null;
}
