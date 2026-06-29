import 'write_operation_notifier.dart';

class BlockActionNotifier extends WriteOperationNotifier<bool> {
  final Map<String, String> _accountIdCache = {};

  BlockActionNotifier(super.redditClient, super.sessionCookie);

  Future<String> _resolveAccountId(String username) async {
    final cached = _accountIdCache[username];
    if (cached != null) return cached;
    final sc = sessionCookie;
    if (sc == null) throw Exception('No session');
    final accountId = await redditClient.fetchAccountId(
      username,
      sessionCookie: sc,
    );
    _accountIdCache[username] = accountId;
    return accountId;
  }

  Future<void> block(String username) async {
    final previous = state[username];
    if (previous == true) return;
    final sc = sessionCookie;
    if (sc == null) throw Exception('No session');
    final accountId = await _resolveAccountId(username);
    await write(username, true, previous, () async {
      await redditClient.blockUser(accountId, sc);
    });
  }

  Future<void> unblock(String username) async {
    final previous = state[username];
    if (previous == false) return;
    final sc = sessionCookie;
    if (sc == null) throw Exception('No session');
    final accountId = await _resolveAccountId(username);
    optimisticSet(username, false);
    try {
      await redditClient.unblockUser(accountId, sc);
    } catch (e) {
      optimisticRevert(username, previous);
      rethrow;
    }
  }

  bool isBlocked(String username) => state[username] ?? false;

  /// Block using a known accountId directly (for profile screen where
  /// the id is already loaded). Skips the username-to-id resolution.
  Future<void> blockKnown(String username, String accountId) async {
    final previous = state[username];
    if (previous == true) return;
    final sc = sessionCookie;
    if (sc == null) throw Exception('No session');
    _accountIdCache[username] = accountId;
    await write(username, true, previous, () async {
      await redditClient.blockUser(accountId, sc);
    });
  }

  /// Unblock using a known accountId directly.
  Future<void> unblockKnown(String username, String accountId) async {
    final previous = state[username];
    if (previous == false) return;
    final sc = sessionCookie;
    if (sc == null) throw Exception('No session');
    _accountIdCache[username] = accountId;
    optimisticSet(username, false);
    try {
      await redditClient.unblockUser(accountId, sc);
    } catch (e) {
      optimisticRevert(username, previous);
      rethrow;
    }
  }
}
