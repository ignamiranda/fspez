import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../domain/models/session_cookie.dart';
import 'reddit_client.dart';

class HttpTransport {
  static const baseUrl = 'https://www.reddit.com';
  static const readBaseUrl = 'https://old.reddit.com';
  static const _browserUA =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36';

  final http.Client _httpClient;

  HttpTransport({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  Uri readJsonUri(String path, {Map<String, String>? queryParams}) {
    return Uri.parse('$readBaseUrl$path.json')
        .replace(queryParameters: queryParams);
  }

  Uri webUri(String path, {Map<String, String>? queryParams}) {
    return Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);
  }

  Uri oldRedditUri(String path, {Map<String, String>? queryParams}) {
    return Uri.parse('https://old.reddit.com$path')
        .replace(queryParameters: queryParams);
  }

  Future<http.Response> get(
    Uri uri,
    ApiEndpoint endpoint,
    SessionCookie? cookie,
  ) {
    return _httpClient.get(uri, headers: _headersFor(endpoint, cookie));
  }

  Future<http.Response> post(
    Uri uri,
    ApiEndpoint endpoint,
    SessionCookie? cookie, {
    String? body,
  }) {
    return _httpClient.post(uri,
        headers: _headersFor(endpoint, cookie), body: body);
  }

  Future<http.Response> postJson(
    Uri uri,
    ApiEndpoint endpoint,
    SessionCookie? cookie, {
    Map<String, dynamic>? body,
  }) {
    return _httpClient.post(
      uri,
      headers: _headersFor(endpoint, cookie),
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> getHtml(Uri uri, SessionCookie? cookie) {
    return _httpClient.get(uri, headers: _headersForHtml(cookie));
  }

  Future<void> putBytes(Uri uri, Uint8List bytes,
      {Map<String, String>? headers}) async {
    final response = await _httpClient.put(
      uri,
      headers: headers,
      body: bytes,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw RedditApiException(
      statusCode: response.statusCode,
      message: response.body,
    );
  }

  Map<String, dynamic> handleJsonResponse(http.Response response) {
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

  dynamic handleRawJsonResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw RedditApiException(
      statusCode: response.statusCode,
      message: response.body,
    );
  }

  void dispose() {
    _httpClient.close();
  }

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
      case ApiEndpoint.submit:
        return _formHeaders(cookie, useBrowserUA: true);
      case ApiEndpoint.comment:
      case ApiEndpoint.compose:
        return _formHeaders(cookie, useBrowserUA: false);
      case ApiEndpoint.mediaUpload:
        return {
          'User-Agent': 'fspez/0.1.0',
          'Content-Type': 'application/json',
          if (cookie != null) 'Cookie': 'reddit_session=${cookie.value}',
          if (cookie?.modhash != null) 'X-Modhash': cookie!.modhash!,
        };
    }
  }

  Map<String, String> _formHeaders(SessionCookie? cookie,
      {bool useBrowserUA = false}) {
    final c = cookie?.rawCookie ?? 'reddit_session=${cookie?.value ?? ''}';
    return {
      'User-Agent': useBrowserUA ? _browserUA : 'fspez/0.1.0',
      'Content-Type':
          'application/x-www-form-urlencoded${useBrowserUA ? '; charset=UTF-8' : ''}',
      'Cookie': c,
      if (useBrowserUA) 'Accept': '*/*',
      if (useBrowserUA) 'X-Requested-With': 'XMLHttpRequest',
      if (cookie?.modhash != null) 'X-Modhash': cookie!.modhash!,
    };
  }

  Map<String, String> _headersForHtml(SessionCookie? cookie) {
    final c = cookie?.rawCookie ?? 'reddit_session=${cookie?.value ?? ''}';
    return {
      'User-Agent': _browserUA,
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Cookie': c,
    };
  }
}
