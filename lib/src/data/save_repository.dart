import '../domain/models/session_cookie.dart';
import 'reddit_client.dart';

class SaveRepository {
  final RedditClient _client;

  SaveRepository(this._client);

  Future<void> save(String fullname, {SessionCookie? sessionCookie}) async {
    if (sessionCookie == null) throw const SaveException(statusCode: 0, body: 'No session');
    try {
      await _client.save(fullname, sessionCookie);
    } on RedditApiException catch (e) {
      throw SaveException(statusCode: e.statusCode, body: e.message);
    }
  }

  Future<void> unsave(String fullname, {SessionCookie? sessionCookie}) async {
    if (sessionCookie == null) throw const SaveException(statusCode: 0, body: 'No session');
    try {
      await _client.unsave(fullname, sessionCookie);
    } on RedditApiException catch (e) {
      throw SaveException(statusCode: e.statusCode, body: e.message);
    }
  }
}

class SaveException implements Exception {
  final int statusCode;
  final String body;
  const SaveException({required this.statusCode, required this.body});
  @override
  String toString() => 'SaveException($statusCode): ${body.length > 200 ? body.substring(0, 200) : body}';
}
