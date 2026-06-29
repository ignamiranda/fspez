import 'account_client.dart';
import 'write_operation_notifier.dart';

class BlockActionNotifier extends WriteOperationNotifier<bool> {
  final AccountClient _client;
  final Map<String, String> _accountIdCache = {};

  BlockActionNotifier(this._client, super.sessionCookie);

  Future<String> _resolveAccountId(String username) async {
    final cached = _accountIdCache[username];
    if (cached != null) return cached;
    final sc = sessionCookie;
    if (sc == null) throw Exception('No session');
    final accountId = await _client.fetchAccountId(
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
      await _client.blockUser(accountId, sc);
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
      await _client.unblockUser(accountId, sc);
    } catch (e) {
      optimisticRevert(username, previous);
      rethrow;
    }
  }

  bool isBlocked(String username) => state[username] ?? false;

  Future<void> blockKnown(String username, String accountId) async {
    final previous = state[username];
    if (previous == true) return;
    final sc = sessionCookie;
    if (sc == null) throw Exception('No session');
    _accountIdCache[username] = accountId;
    await write(username, true, previous, () async {
      await _client.blockUser(accountId, sc);
    });
  }

  Future<void> unblockKnown(String username, String accountId) async {
    final previous = state[username];
    if (previous == false) return;
    final sc = sessionCookie;
    if (sc == null) throw Exception('No session');
    _accountIdCache[username] = accountId;
    optimisticSet(username, false);
    try {
      await _client.unblockUser(accountId, sc);
    } catch (e) {
      optimisticRevert(username, previous);
      rethrow;
    }
  }
}
