import 'dart:convert';

import '../domain/models/session_cookie.dart';
import 'http_transport.dart';
import 'reddit_client.dart';

/// Client for post interaction actions: vote, save, hide, delete, edit, report.
class InteractionClient {
  final HttpTransport _transport;

  InteractionClient(this._transport);

  Future<void> vote({
    required String fullname,
    required int direction,
    required SessionCookie sessionCookie,
  }) async {
    await _postForm(
      '/api/vote',
      {'id': fullname, 'dir': direction.toString()},
      sessionCookie,
    );
  }

  Future<void> save(String fullname, SessionCookie sessionCookie) async {
    await _oldRedditPost('/api/save', fullname, sessionCookie);
  }

  Future<void> unsave(String fullname, SessionCookie sessionCookie) async {
    await _oldRedditPost('/api/unsave', fullname, sessionCookie);
  }

  Future<void> hide(String fullname, SessionCookie sessionCookie) async {
    await _postForm('/api/hide', {'id': fullname}, sessionCookie);
  }

  Future<void> unhide(String fullname, SessionCookie sessionCookie) async {
    await _postForm('/api/unhide', {'id': fullname}, sessionCookie);
  }

  Future<void> deleteContent(
    String fullname,
    SessionCookie sessionCookie,
  ) async {
    await _oldRedditPost('/api/del', fullname, sessionCookie);
  }

  Future<void> editContent({
    required String thingId,
    required String text,
    required SessionCookie sessionCookie,
  }) async {
    final fields = <String, String>{
      'thing_id': thingId,
      'text': text,
      if (sessionCookie.modhash != null) 'uh': sessionCookie.modhash!,
    };
    final uri = _transport.webUri('/api/editusertext');
    final response = await _transport.post(
      uri,
      ApiEndpoint.comment,
      sessionCookie,
      body: Uri(queryParameters: fields).query,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw RedditApiException(
      statusCode: response.statusCode,
      message: response.body,
    );
  }

  Future<void> reportContent({
    required String thingId,
    required String reason,
    required SessionCookie sessionCookie,
  }) async {
    await _postForm(
      '/api/report',
      {'api_type': 'json', 'thing_id': thingId, 'reason': reason},
      sessionCookie,
    );
  }

  Future<void> _oldRedditPost(
    String path,
    String fullname,
    SessionCookie sessionCookie,
  ) async {
    final uri = _transport.oldRedditUri(path);
    final response = await _transport.post(
      uri,
      ApiEndpoint.oldReddit,
      sessionCookie,
      body: 'id=$fullname',
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final ct = (response.headers['content-type'] ?? '').toLowerCase();
      if (!ct.contains('text/html')) return;
    }
    throw RedditApiException(
      statusCode: response.statusCode,
      message: response.body,
    );
  }

  Future<void> _postForm(
    String path,
    Map<String, String> fields,
    SessionCookie sessionCookie,
  ) async {
    final response =
        await _transport.postForm(path, fields, sessionCookie);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return;
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return;
      return;
    }
    throw RedditApiException(
      statusCode: response.statusCode,
      message: response.body,
    );
  }
}
