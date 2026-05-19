import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/models/session_cookie.dart';

class RedditClient {
  static const _baseUrl = 'https://www.reddit.com';

  final http.Client _httpClient;

  RedditClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  Map<String, String> _headers(SessionCookie? sessionCookie) => {
        'User-Agent': 'fspez/0.1.0',
        'Content-Type': 'application/json',
        if (sessionCookie != null)
          'Cookie': 'reddit_session=${sessionCookie.value}',
      };

  Future<Map<String, dynamic>> get(String path,
      {Map<String, String>? queryParams,
      SessionCookie? sessionCookie}) async {
    final uri = Uri.parse('$_baseUrl$path.json')
        .replace(queryParameters: queryParams);
    final response =
        await _httpClient.get(uri, headers: _headers(sessionCookie));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic>? body, SessionCookie? sessionCookie}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await _httpClient.post(
      uri,
      headers: _headers(sessionCookie),
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
        await _httpClient.get(uri, headers: _headers(sessionCookie));
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
      headers: {
        'User-Agent': 'fspez/0.1.0',
        'Content-Type': 'application/x-www-form-urlencoded',
        if (sessionCookie != null)
          'Cookie': 'reddit_session=${sessionCookie.value}',
      },
      body: fields != null ? Uri(queryParameters: fields).query : null,
    );
    return _handleResponse(response);
  }

  Future<void> save(String fullname, SessionCookie sessionCookie) async {
    await _oldRedditPost('/api/save', fullname, sessionCookie);
  }

  Future<void> unsave(String fullname, SessionCookie sessionCookie) async {
    await _oldRedditPost('/api/unsave', fullname, sessionCookie);
  }

  Future<void> _oldRedditPost(String path, String fullname, SessionCookie sessionCookie) async {
    final cookie = sessionCookie.rawCookie ?? 'reddit_session=${sessionCookie.value}';
    final uri = Uri.parse('https://old.reddit.com$path');
    final response = await _httpClient.post(
      uri,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        'Accept': '*/*',
        'X-Requested-With': 'XMLHttpRequest',
        'Cookie': cookie,
        if (sessionCookie.modhash != null) 'X-Modhash': sessionCookie.modhash!,
      },
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

  void dispose() {
    _httpClient.close();
  }
}

class RedditApiException implements Exception {
  final int statusCode;
  final String message;

  const RedditApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'RedditApiException($statusCode): $message';
}
