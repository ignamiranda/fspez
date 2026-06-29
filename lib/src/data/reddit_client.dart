import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/models/session_cookie.dart';
import 'http_transport.dart';

/// Generic read API client for repositories and infrastructure.
///
/// Domain-specific write operations have been moved to focused clients:
/// [InteractionClient], [SubmitClient], [MessageClient], [AccountClient].
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

  void dispose() {
    _transport.dispose();
  }
}

class RedditApiException implements Exception {
  final int statusCode;
  final String message;

  const RedditApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'RedditApiException($statusCode): $message';
}
