import '../domain/models/session_cookie.dart';
import 'http_transport.dart';
import 'reddit_client.dart';
import 'shreddit_json_extractor.dart';
import 'html_parser_utils.dart';
import 'write_operation_notifier.dart';

class BlockActionNotifier extends WriteOperationNotifier<bool> {
  final HttpTransport _transport;
  final Map<String, String> _accountIdCache = {};

  BlockActionNotifier(this._transport, super.sessionCookie);

  Future<String> _resolveAccountId(String username) async {
    final cached = _accountIdCache[username];
    if (cached != null) return cached;
    final sc = sessionCookie;
    if (sc == null) throw Exception('No session');
    final uri = _transport.webUri('/user/$username');
    final response = await _transport.getHtml(uri, sc);
    final json = ShredditJsonExtractor.extract(response.body);
    final pp = pageProps(json);
    final raw = (pp['user'] as Map<String, dynamic>?) ??
        (pp['profile'] as Map<String, dynamic>?) ??
        {};
    final id = raw['id'] as String? ?? '';
    final accountId = 't2_$id';
    _accountIdCache[username] = accountId;
    return accountId;
  }

  Future<void> block(String username, {String? accountId}) async {
    await _setBlocked(username, true, accountId: accountId);
  }

  Future<void> unblock(String username, {String? accountId}) async {
    await _setBlocked(username, false, accountId: accountId);
  }

  bool isBlocked(String username) => state[username] ?? false;

  Future<void> _setBlocked(String username, bool block,
      {String? accountId}) async {
    final previous = state[username];
    if (previous == block) return;
    final sc = sessionCookie;
    if (sc == null) throw Exception('No session');
    final resolvedId = accountId ?? await _resolveAccountId(username);
    if (accountId != null) _accountIdCache[username] = accountId;
    await write(username, block, previous, () async {
      await _postBlock(resolvedId, sc, block: block);
    });
  }

  Future<void> _postBlock(
    String accountId,
    SessionCookie sessionCookie, {
    required bool block,
  }) async {
    final path = block ? '/api/block' : '/api/unblock';
    final response = await _transport.postForm(
      path,
      {'account_id': accountId},
      sessionCookie,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw RedditApiException(
      statusCode: response.statusCode,
      message: response.body,
    );
  }
}
