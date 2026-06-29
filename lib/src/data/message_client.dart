import 'dart:convert';

import '../domain/models/session_cookie.dart';
import 'http_transport.dart';
import 'reddit_client.dart';

/// Client for private message and comment operations.
class MessageClient {
  final HttpTransport _transport;

  MessageClient(this._transport);

  Future<void> compose({
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
      return;
    }
    throw RedditApiException(
      statusCode: response.statusCode,
      message: response.body,
    );
  }

  Future<void> comment({
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
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw RedditApiException(
      statusCode: response.statusCode,
      message: response.body,
    );
  }
}
