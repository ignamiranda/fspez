import '../domain/models/flair_option.dart';
import '../domain/models/session_cookie.dart';
import 'http_transport.dart';
import 'media_upload_response.dart';
import 'reddit_client.dart';

/// Client for post submission and media upload lease requests.
class SubmitClient {
  final HttpTransport _transport;

  SubmitClient(this._transport);

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
      if (!ct.contains('text/html')) return {'success': true};
    }
    throw RedditApiException(
      statusCode: response.statusCode,
      message: response.body,
    );
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
}
