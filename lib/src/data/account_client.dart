import '../domain/models/session_cookie.dart';
import 'http_transport.dart';
import 'reddit_client.dart';

/// Client for account-level operations: block, unblock, fetch account ID.
class AccountClient {
  final HttpTransport _transport;

  AccountClient(this._transport);

  Future<String> fetchAccountId(
    String username, {
    SessionCookie? sessionCookie,
  }) async {
    final data = await _get('/user/$username/about', sessionCookie: sessionCookie);
    final about = data['data'] as Map<String, dynamic>;
    final id = about['id'] as String? ?? '';
    return 't2_$id';
  }

  Future<void> blockUser(String accountId, SessionCookie sessionCookie) async {
    await _postForm(
      '/api/block',
      {'account_id': accountId},
      sessionCookie,
    );
  }

  Future<void> unblockUser(
    String accountId,
    SessionCookie sessionCookie,
  ) async {
    await _postForm(
      '/api/unblock',
      {'account_id': accountId},
      sessionCookie,
    );
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, String>? queryParams,
    SessionCookie? sessionCookie,
  }) async {
    final uri = _transport.readJsonUri(path, queryParams: queryParams);
    final response = await _transport.get(uri, ApiEndpoint.json, sessionCookie);
    return _transport.handleJsonResponse(response);
  }

  Future<void> _postForm(
    String path,
    Map<String, String> fields,
    SessionCookie sessionCookie,
  ) async {
    final uri = _transport.webUri(path);
    final response = await _transport.post(
      uri,
      ApiEndpoint.form,
      sessionCookie,
      body: Uri(queryParameters: fields).query,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw RedditApiException(
      statusCode: response.statusCode,
      message: response.body,
    );
  }
}
