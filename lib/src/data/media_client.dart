import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../domain/models/media_upload_result.dart';
import '../domain/models/session_cookie.dart';
import 'reddit_client.dart';

/// Orchestrates the two-step media upload to Reddit:
/// 1. Request upload lease via RedditClient (POST /api/media/asset.json)
/// 2. Upload raw file bytes to the returned S3 presigned URL
class MediaUploadClient {
  final RedditClient _redditClient;
  final http.Client _httpClient;

  MediaUploadClient(this._redditClient, {http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// Upload a single image file. Returns the Reddit asset ID and CDN URL.
  Future<MediaUploadResult> uploadImage({
    required Uint8List bytes,
    required String filename,
    required SessionCookie sessionCookie,
  }) async {
    final mime = _mimeForImage(filename);
    final lease = await _redditClient.requestUploadAsset(
      filepath: filename,
      mimetype: mime,
      sessionCookie: sessionCookie,
    );
    final response = await _httpClient.put(
      Uri.parse(lease.uploadUrl),
      headers: {'Content-Type': mime},
      body: bytes,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return MediaUploadResult(
        assetId: lease.assetId,
        assetUrl: lease.assetUrl,
      );
    }
    throw MediaUploadException(
      message: 'S3 upload failed: ${response.statusCode} ${response.body}',
    );
  }

  /// Upload a single video file. Returns the Reddit asset ID and CDN URL.
  Future<MediaUploadResult> uploadVideo({
    required Uint8List bytes,
    required String filename,
    required SessionCookie sessionCookie,
  }) async {
    final mime = _mimeForVideo(filename);
    final lease = await _redditClient.requestUploadAsset(
      filepath: filename,
      mimetype: mime,
      sessionCookie: sessionCookie,
    );
    final response = await _httpClient.put(
      Uri.parse(lease.uploadUrl),
      headers: {'Content-Type': mime},
      body: bytes,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return MediaUploadResult(
        assetId: lease.assetId,
        assetUrl: lease.assetUrl,
      );
    }
    throw MediaUploadException(
      message: 'S3 upload failed: ${response.statusCode} ${response.body}',
    );
  }

  void dispose() {
    _httpClient.close();
  }

  String _mimeForImage(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  String _mimeForVideo(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'webm':
        return 'video/webm';
      case 'mp4':
      default:
        return 'video/mp4';
    }
  }
}

class MediaUploadException implements Exception {
  final String message;

  const MediaUploadException({required this.message});

  @override
  String toString() => 'MediaUploadException: $message';
}
