import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/session_cookie.dart';
import 'media_client.dart';
import 'reddit_client.dart';

class SubmitState {
  final bool isSubmitting;
  final String? error;
  final bool success;

  const SubmitState({
    this.isSubmitting = false,
    this.error,
    this.success = false,
  });
}

class SubmitNotifier extends StateNotifier<SubmitState> {
  final RedditClient _client;
  final MediaUploadClient _mediaClient;

  SubmitNotifier(this._client, this._mediaClient) : super(const SubmitState());

  Future<bool> submit({
    required Map<String, String> fields,
    required SessionCookie sessionCookie,
  }) async {
    state = const SubmitState(isSubmitting: true);
    try {
      await _client.submit(fields: fields, sessionCookie: sessionCookie);
      state = const SubmitState(success: true);
      return true;
    } catch (e) {
      state = SubmitState(error: e.toString());
      return false;
    }
  }

  void reset() => state = const SubmitState();

  /// Upload an image and submit as a link post with the image URL.
  Future<bool> submitImage({
    required String title,
    required String subreddit,
    required Uint8List imageBytes,
    required String imageFilename,
    required SessionCookie sessionCookie,
  }) async {
    state = const SubmitState(isSubmitting: true);
    try {
      final media = await _mediaClient.uploadImage(
        bytes: imageBytes,
        filename: imageFilename,
        sessionCookie: sessionCookie,
      );
      final fields = <String, String>{
        'kind': 'link',
        'sr': subreddit,
        'title': title,
        'url': media.assetUrl,
      };
      await _client.submit(fields: fields, sessionCookie: sessionCookie);
      state = const SubmitState(success: true);
      return true;
    } catch (e) {
      state = SubmitState(error: e.toString());
      return false;
    }
  }

  /// Upload a video and submit as a link post with the video URL.
  Future<bool> submitVideo({
    required String title,
    required String subreddit,
    required Uint8List videoBytes,
    required String videoFilename,
    required SessionCookie sessionCookie,
  }) async {
    state = const SubmitState(isSubmitting: true);
    try {
      final media = await _mediaClient.uploadVideo(
        bytes: videoBytes,
        filename: videoFilename,
        sessionCookie: sessionCookie,
      );
      final fields = <String, String>{
        'kind': 'link',
        'sr': subreddit,
        'title': title,
        'url': media.assetUrl,
      };
      await _client.submit(fields: fields, sessionCookie: sessionCookie);
      state = const SubmitState(success: true);
      return true;
    } catch (e) {
      state = SubmitState(error: e.toString());
      return false;
    }
  }

  /// Upload multiple images and submit as a gallery post via submit_gallery_post.json.
  Future<bool> submitGallery({
    required String title,
    required String subreddit,
    required List<({Uint8List bytes, String filename, String caption})> items,
    required SessionCookie sessionCookie,
  }) async {
    state = const SubmitState(isSubmitting: true);
    try {
      final uploads = <({String mediaId, String caption})>[];
      for (final item in items) {
        final media = await _mediaClient.uploadImage(
          bytes: item.bytes,
          filename: item.filename,
          sessionCookie: sessionCookie,
        );
        uploads.add((mediaId: media.assetId, caption: item.caption));
      }
      final galleryItems = jsonEncode(
        uploads
            .map((u) => <String, String>{
                  'media_id': u.mediaId,
                  'caption': u.caption,
                })
            .toList(),
      );
      final fields = <String, String>{
        'api_type': 'json',
        'kind': 'gallery',
        'sr': subreddit,
        'title': title,
        'items': galleryItems,
      };
      await _client.submitGalleryPost(
          fields: fields, sessionCookie: sessionCookie);
      state = const SubmitState(success: true);
      return true;
    } catch (e) {
      state = SubmitState(error: e.toString());
      return false;
    }
  }
}
