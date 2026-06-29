import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/models/flair_option.dart';
import '../domain/models/session_cookie.dart';
import 'http_transport.dart';
import 'media_upload_response.dart';

enum ApiEndpoint {
  json,
  form,
  oldReddit,
  comment,
  submit,
  compose,
  mediaUpload
}

class RedditClient {
  final HttpTransport _transport;

  RedditClient({http.Client? httpClient, HttpTransport? transport})
    : _transport = transport ?? HttpTransport(httpClient: httpClient);

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
    SessionCookie? sessionCookie,
  }) async {
    final uri = _transport.readJsonUri(path, queryParams: queryParams);
    final response = await _transport.get(uri, ApiEndpoint.json, sessionCookie);
    return _transport.handleJsonResponse(response);
  }

  Future<String> getHtml(
    String path, {
    Map<String, String>? queryParams,
    SessionCookie? sessionCookie,
  }) async {
    final uri = _transport.webUri(path, queryParams: queryParams);
    final response = await _transport.getHtml(uri, sessionCookie);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body;
    }
    throw RedditApiException(
      statusCode: response.statusCode,
      message: response.body,
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    SessionCookie? sessionCookie,
  }) async {
    final uri = _transport.webUri(path);
    final response = await _transport.post(
      uri,
      ApiEndpoint.json,
      sessionCookie,
      body: body != null ? jsonEncode(body) : null,
    );
    return _transport.handleJsonResponse(response);
  }

  Future<dynamic> getRaw(
    String path, {
    Map<String, String>? queryParams,
    SessionCookie? sessionCookie,
  }) async {
    final uri = _transport.readJsonUri(path, queryParams: queryParams);
    final response = await _transport.get(uri, ApiEndpoint.json, sessionCookie);
    return _transport.handleRawJsonResponse(response);
  }

  Future<Map<String, dynamic>> postForm(
    String path, {
    Map<String, String>? fields,
    SessionCookie? sessionCookie,
  }) async {
    final uri = _transport.webUri(path);
    final response = await _transport.post(
      uri,
      ApiEndpoint.form,
      sessionCookie,
      body: fields != null ? Uri(queryParameters: fields).query : null,
    );
    return _transport.handleJsonResponse(response);
  }

  Future<Map<String, dynamic>> submit({
    required Map<String, String> fields,
    required SessionCookie sessionCookie,
  }) async {
    final uri = _transport.oldRedditUri('/api/submit');
    final response = await _transport.post(
      uri,
      ApiEndpoint.submit,
      sessionCookie,
      body: Uri(queryParameters: fields).query,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final ct = (response.headers['content-type'] ?? '').toLowerCase();
      if (!ct.contains('text/html')) {
        return {'success': true};
      }
    }
    throw RedditApiException(
      statusCode: response.statusCode,
      message: response.body,
    );
  }

  Future<UploadLease> requestUploadAsset({
    required String filepath,
    required String mimetype,
    required SessionCookie sessionCookie,
  }) async {
    final uri = _transport.webUri('/api/media/asset.json');
    final response = await _transport.postJson(
      uri,
      ApiEndpoint.mediaUpload,
      sessionCookie,
      body: {'filepath': filepath, 'mimetype': mimetype},
    );
    final json = _transport.handleJsonResponse(response);
    return UploadLease.fromJson(json);
  }

  Future<void> submitGalleryPost({
    required Map<String, String> fields,
    required SessionCookie sessionCookie,
  }) async {
    final uri = _transport.webUri('/api/submit_gallery_post.json');
    final response = await _transport.post(
      uri,
      ApiEndpoint.submit,
      sessionCookie,
      body: Uri(queryParameters: fields).query,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw RedditApiException(
      statusCode: response.statusCode,
      message: response.body,
    );
  }

  Future<void> save(String fullname, SessionCookie sessionCookie) async {
    await _oldRedditPost('/api/save', fullname, sessionCookie);
  }

  Future<void> unsave(String fullname, SessionCookie sessionCookie) async {
    await _oldRedditPost('/api/unsave', fullname, sessionCookie);
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

  Future<Map<String, dynamic>> comment({
    required Map<String, String> fields,
    required SessionCookie sessionCookie,
  }) async {
    final uri = _transport.webUri('/api/comment');
    final response = await _transport.post(
      uri,
      ApiEndpoint.comment,
      sessionCookie,
      body: Uri(queryParameters: fields).query,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true};
    }
    throw RedditApiException(
      statusCode: response.statusCode,
      message: response.body,
    );
  }

  Future<Map<String, dynamic>> compose({
    required Map<String, String> fields,
    required SessionCookie sessionCookie,
  }) async {
    final uri = _transport.webUri('/api/compose');
    final response = await _transport.post(
      uri,
      ApiEndpoint.compose,
      sessionCookie,
      body: Uri(queryParameters: fields).query,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final jsonField = decoded['json'];
          if (jsonField is Map) {
            final errors = jsonField['errors'];
            if (errors is List && errors.isNotEmpty) {
              throw RedditApiException(
                statusCode: response.statusCode,
                message: response.body,
              );
            }
          }
          if (decoded['error'] != null) {
            throw RedditApiException(
              statusCode: response.statusCode,
              message: response.body,
            );
          }
        }
      } catch (_) {}
      return {'success': true};
    }
    throw RedditApiException(
      statusCode: response.statusCode,
      message: response.body,
    );
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
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw RedditApiException(
      statusCode: response.statusCode,
      message: response.body,
    );
  }

  void dispose() {
    _transport.dispose();
  }

  Future<void> deleteContent(
    String fullname,
    SessionCookie sessionCookie,
  ) async {
    await _oldRedditPost('/api/del', fullname, sessionCookie);
  }

  Future<void> reportContent({
    required String thingId,
    required String reason,
    SessionCookie? sessionCookie,
  }) async {
    await postForm(
      '/api/report',
      fields: {'api_type': 'json', 'thing_id': thingId, 'reason': reason},
      sessionCookie: sessionCookie,
    );
  }

  Future<void> hide(String fullname, SessionCookie sessionCookie) async {
    await postForm(
      '/api/hide',
      fields: {'id': fullname},
      sessionCookie: sessionCookie,
    );
  }

  Future<void> unhide(String fullname, SessionCookie sessionCookie) async {
    await postForm(
      '/api/unhide',
      fields: {'id': fullname},
      sessionCookie: sessionCookie,
    );
  }

  /// Fetches post flair templates for [subreddit] via the www API endpoint.
  ///
  /// Returns an empty list on failure or when the subreddit has no flairs.
  Future<List<FlairOption>> fetchFlairOptions(
    String subreddit,
    SessionCookie? sessionCookie,
  ) async {
    try {
      final uri = _transport.webUri('/api/v1/$subreddit/post_flairs');
      final response = await _transport.get(
        uri,
        ApiEndpoint.json,
        sessionCookie,
      );
      final decoded = _transport.handleRawJsonResponse(response);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((e) => FlairOption.fromJson(e))
            .toList();
      }
      if (decoded is Map<String, dynamic>) {
        final templates =
            decoded['subreddit_flair_templates'] as List<dynamic>?;
        if (templates != null) {
          return templates
              .whereType<Map<String, dynamic>>()
              .map((e) => FlairOption.fromJson(e))
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<void> blockUser(String accountId, SessionCookie sessionCookie) async {
    await postForm(
      '/api/block',
      fields: {'account_id': accountId},
      sessionCookie: sessionCookie,
    );
  }

  Future<void> unblockUser(
    String accountId,
    SessionCookie sessionCookie,
  ) async {
    await postForm(
      '/api/unblock',
      fields: {'account_id': accountId},
      sessionCookie: sessionCookie,
    );
  }

  Future<String> fetchAccountId(
    String username, {
    SessionCookie? sessionCookie,
  }) async {
    final data = await get(
      '/user/$username/about',
      sessionCookie: sessionCookie,
    );
    final about = data['data'] as Map<String, dynamic>;
    final id = about['id'] as String? ?? '';
    return 't2_$id';
  }
}

class RedditApiException implements Exception {
  final int statusCode;
  final String message;

  const RedditApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'RedditApiException($statusCode): $message';
}
