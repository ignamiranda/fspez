import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/models/session_cookie.dart';

class RedditClient {
  static const _baseUrl = 'https://www.reddit.com';

  final http.Client _httpClient;
  SessionCookie? _sessionCookie;

  RedditClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  void setSessionCookie(SessionCookie cookie) {
    _sessionCookie = cookie;
  }

  void clearSessionCookie() {
    _sessionCookie = null;
  }

  Map<String, String> get _headers => {
        'User-Agent': 'fspez/0.1.0',
        'Content-Type': 'application/json',
        if (_sessionCookie != null)
          'Cookie': 'reddit_session=${_sessionCookie!.value}',
      };

  Future<Map<String, dynamic>> get(String path,
      {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$_baseUrl$path.json')
        .replace(queryParameters: queryParams);
    final response = await _httpClient.get(uri, headers: _headers);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await _httpClient.post(
      uri,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
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
