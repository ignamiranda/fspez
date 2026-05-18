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
