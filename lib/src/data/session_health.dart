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
    final me =
        await redditClient.get('/api/me', sessionCookie: account.sessionCookie);
    final data = me['data'] as Map<String, dynamic>?;
    final username = data?['name'] as String?;
    final apiModhash = data?['modhash'] as String?;

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
      if (apiModhash != null) {
        return SessionHealth._(
          status: SessionHealthStatus.healthy,
          title: 'Session healthy',
          message: '',
          actionLabel: '',
          newModhash: apiModhash,
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
  } catch (_) {
    return SessionHealth.unknown;
  }
}
