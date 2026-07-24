import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/session_cookie.dart';
import 'media_client.dart';
import 'submit_client.dart';

class SubmitState {
  final bool isSubmitting;
  final String? error;
  final bool success;

  const SubmitState({
    this.isSubmitting = false,
    this.error,
    this.success = false,
  });

  bool get canSubmit => !isSubmitting;

  SubmitState copyWith({
    bool? isSubmitting,
    String? error,
    bool? success,
    bool clearError = false,
  }) {
    return SubmitState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      success: success ?? this.success,
    );
  }
}

class SubmitNotifier extends StateNotifier<SubmitState> {
  final SubmitClient _client;
  final MediaUploadClient _mediaClient;

  SubmitNotifier(this._client, this._mediaClient) : super(const SubmitState());

  bool get canSubmit => state.canSubmit;

  Future<bool> submit({
    required Map<String, String> fields,
    required SessionCookie sessionCookie,
  }) async {
    if (!canSubmit) return false;
    state = state.copyWith(isSubmitting: true);
    try {
      await _client.submit(fields: fields, sessionCookie: sessionCookie);
      state = const SubmitState(success: true);
      return true;
    } catch (e) {
      state = SubmitState(error: e.toString());
      return false;
    }
  }

  Future<bool> submitText({
    required String title,
    required String subreddit,
    required String text,
    required SessionCookie sessionCookie,
    String? flairId,
    String? flairText,
  }) async {
    final modhash = sessionCookie.modhash ?? '';
    final fields = <String, String>{
      'kind': 'self',
      'sr': subreddit,
      'title': title,
      'uh': modhash,
    };
    if (text.isNotEmpty) fields['text'] = text;
    if (flairId != null) fields['flair_id'] = flairId;
    if (flairText != null) fields['flair_text'] = flairText;
    return submit(fields: fields, sessionCookie: sessionCookie);
  }

  Future<bool> submitLink({
    required String title,
    required String subreddit,
    required String url,
    required SessionCookie sessionCookie,
    String? flairId,
    String? flairText,
  }) async {
    final modhash = sessionCookie.modhash ?? '';
    final fields = <String, String>{
      'kind': 'link',
      'sr': subreddit,
      'title': title,
      'uh': modhash,
    };
    if (url.isNotEmpty) fields['url'] = url;
    if (flairId != null) fields['flair_id'] = flairId;
    if (flairText != null) fields['flair_text'] = flairText;
    return submit(fields: fields, sessionCookie: sessionCookie);
  }

  Future<bool> submitImage({
    required String title,
    required String subreddit,
    required Uint8List bytes,
    required String filename,
    required SessionCookie sessionCookie,
    String? flairId,
    String? flairText,
  }) async {
    state = const SubmitState(isSubmitting: true);
    try {
      final media = await _mediaClient.uploadImage(
        bytes: bytes,
        filename: filename,
        sessionCookie: sessionCookie,
      );
      final fields = <String, String>{
        'kind': 'link',
        'sr': subreddit,
        'title': title,
        'url': media.assetUrl,
      };
      if (flairId != null) fields['flair_id'] = flairId;
      if (flairText != null) fields['flair_text'] = flairText;
      await _client.submit(fields: fields, sessionCookie: sessionCookie);
      state = const SubmitState(success: true);
      return true;
    } catch (e) {
      state = SubmitState(error: e.toString());
      return false;
    }
  }

  Future<bool> submitVideo({
    required String title,
    required String subreddit,
    required Uint8List bytes,
    required String filename,
    required SessionCookie sessionCookie,
    String? flairId,
    String? flairText,
  }) async {
    state = const SubmitState(isSubmitting: true);
    try {
      final media = await _mediaClient.uploadVideo(
        bytes: bytes,
        filename: filename,
        sessionCookie: sessionCookie,
      );
      final fields = <String, String>{
        'kind': 'link',
        'sr': subreddit,
        'title': title,
        'url': media.assetUrl,
      };
      if (flairId != null) fields['flair_id'] = flairId;
      if (flairText != null) fields['flair_text'] = flairText;
      await _client.submit(fields: fields, sessionCookie: sessionCookie);
      state = const SubmitState(success: true);
      return true;
    } catch (e) {
      state = SubmitState(error: e.toString());
      return false;
    }
  }

  Future<bool> submitGallery({
    required String title,
    required String subreddit,
    required List<({Uint8List bytes, String filename, String caption})> items,
    required SessionCookie sessionCookie,
    String? flairId,
    String? flairText,
  }) async {
    state = const SubmitState(isSubmitting: true);
    try {
      if (items.isEmpty) {
        state = const SubmitState(error: 'No valid images selected');
        return false;
      }
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
      if (flairId != null) fields['flair_id'] = flairId;
      if (flairText != null) fields['flair_text'] = flairText;
      await _client.submitGalleryPost(
          fields: fields, sessionCookie: sessionCookie);
      state = const SubmitState(success: true);
      return true;
    } catch (e) {
      state = SubmitState(error: e.toString());
      return false;
    }
  }

  void reset() => state = const SubmitState();
}
