import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/models/session_cookie.dart';

enum ApiEndpoint { json, form, oldReddit, comment, submit, compose }

class RedditClient {
  static const _baseUrl = 'https://www.reddit.com';
  static const _browserUA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36';

  final http.Client _httpClient;

  RedditClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  Map<String, String> _headersFor(ApiEndpoint kind, SessionCookie? cookie) {
    switch (kind) {
      case ApiEndpoint.json:
        return {
          'User-Agent': 'fspez/0.1.0',
          'Content-Type': 'application/json',
          if (cookie != null) 'Cookie': 'reddit_session=${cookie.value}',
        };
      case ApiEndpoint.form:
        return {
          'User-Agent': 'fspez/0.1.0',
          'Content-Type': 'application/x-www-form-urlencoded',
          if (cookie != null) 'Cookie': 'reddit_session=${cookie.value}',
        };
      case ApiEndpoint.oldReddit:
        final c = cookie?.rawCookie ?? 'reddit_session=${cookie?.value ?? ''}';
        return {
          'User-Agent': _browserUA,
          'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
          'Accept': '*/*',
          'X-Requested-With': 'XMLHttpRequest',
          'Cookie': c,
          if (cookie?.modhash != null) 'X-Modhash': cookie!.modhash!,
        };
      case ApiEndpoint.comment:
        final c = cookie?.rawCookie ?? 'reddit_session=${cookie?.value ?? ''}';
        return {
          'User-Agent': 'fspez/0.1.0',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Cookie': c,
          if (cookie?.modhash != null) 'X-Modhash': cookie!.modhash!,
        };
      case ApiEndpoint.submit:
        final c = cookie?.rawCookie ?? 'reddit_session=${cookie?.value ?? ''}';
        return {
          'User-Agent': _browserUA,
          'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
          'Accept': '*/*',
          'X-Requested-With': 'XMLHttpRequest',
          'Cookie': c,
          if (cookie?.modhash != null) 'X-Modhash': cookie!.modhash!,
        };
      case ApiEndpoint.compose:
        final c = cookie?.rawCookie ?? 'reddit_session=${cookie?.value ?? ''}';
        return {
          'User-Agent': 'fspez/0.1.0',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Cookie': c,
          if (cookie?.modhash != null) 'X-Modhash': cookie!.modhash!,
        };
    }
  }

  Future<Map<String, dynamic>> get(String path,
      {Map<String, String>? queryParams,
      SessionCookie? sessionCookie}) async {
    final uri = Uri.parse('$_baseUrl$path.json')
        .replace(queryParameters: queryParams);
    final response =
        await _httpClient.get(uri, headers: _headersFor(ApiEndpoint.json, sessionCookie));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic>? body, SessionCookie? sessionCookie}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await _httpClient.post(
      uri,
      headers: _headersFor(ApiEndpoint.json, sessionCookie),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    }
    throw RedditApiException(
      statusCode: response.statusCode,
      message: response.body,
    );
  }

  Future<dynamic> getRaw(String path,
      {Map<String, String>? queryParams,
      SessionCookie? sessionCookie}) async {
    final uri = Uri.parse('$_baseUrl$path.json')
        .replace(queryParameters: queryParams);
    final response =
        await _httpClient.get(uri, headers: _headersFor(ApiEndpoint.json, sessionCookie));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw RedditApiException(
      statusCode: response.statusCode,
      message: response.body,
    );
  }

  Future<Map<String, dynamic>> postForm(String path,
      {Map<String, String>? fields,
      SessionCookie? sessionCookie}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await _httpClient.post(
      uri,
      headers: _headersFor(ApiEndpoint.form, sessionCookie),
      body: fields != null ? Uri(queryParameters: fields).query : null,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> submit({
    required Map<String, String> fields,
    required SessionCookie sessionCookie,
  }) async {
    final uri = Uri.parse('https://old.reddit.com/api/submit');
    final response = await _httpClient.post(
      uri,
      headers: _headersFor(ApiEndpoint.submit, sessionCookie),
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

  Future<void> save(String fullname, SessionCookie sessionCookie) async {
    await _oldRedditPost('/api/save', fullname, sessionCookie);
  }

  Future<void> unsave(String fullname, SessionCookie sessionCookie) async {
    await _oldRedditPost('/api/unsave', fullname, sessionCookie);
  }

  Future<void> _oldRedditPost(String path, String fullname, SessionCookie sessionCookie) async {
    final uri = Uri.parse('https://old.reddit.com$path');
    final response = await _httpClient.post(
      uri,
      headers: _headersFor(ApiEndpoint.oldReddit, sessionCookie),
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
    final uri = Uri.parse('https://www.reddit.com/api/comment');
    final response = await _httpClient.post(
      uri,
      headers: _headersFor(ApiEndpoint.comment, sessionCookie),
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
    final uri = Uri.parse('https://www.reddit.com/api/compose');
    final response = await _httpClient.post(
      uri,
      headers: _headersFor(ApiEndpoint.compose, sessionCookie),
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
              throw RedditApiException(statusCode: response.statusCode, message: response.body);
            }
          }
          if (decoded['error'] != null) {
            throw RedditApiException(statusCode: response.statusCode, message: response.body);
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
    final uri = Uri.parse('https://www.reddit.com/api/editusertext');
    final response = await _httpClient.post(
      uri,
      headers: _headersFor(ApiEndpoint.comment, sessionCookie),
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
    _httpClient.close();
  }

  Future<void> deleteContent(String fullname, SessionCookie sessionCookie) async {
    await _oldRedditPost('/api/del', fullname, sessionCookie);
  }

  Future<void> hide(String fullname, SessionCookie sessionCookie) async {
    await postForm('/api/hide', fields: {'id': fullname}, sessionCookie: sessionCookie);
  }

  Future<void> unhide(String fullname, SessionCookie sessionCookie) async {
    await postForm('/api/unhide', fields: {'id': fullname}, sessionCookie: sessionCookie);
  }
}

class RedditApiException implements Exception {
  final int statusCode;
  final String message;

  const RedditApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'RedditApiException($statusCode): $message';
}
