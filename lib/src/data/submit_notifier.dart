import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/flair_option.dart';
import '../domain/models/session_cookie.dart';
import 'media_client.dart';
import 'submit_client.dart';

class SubmitState {
  final bool isSubmitting;
  final String? error;
  final bool success;

  // Flair state
  final List<FlairOption> flairOptions;
  final FlairOption? selectedFlair;
  final bool isFlairRequired;
  final bool isFetchingFlairs;

  const SubmitState({
    this.isSubmitting = false,
    this.error,
    this.success = false,
    this.flairOptions = const [],
    this.selectedFlair,
    this.isFlairRequired = false,
    this.isFetchingFlairs = false,
  });

  bool get canSubmit =>
      !isSubmitting &&
      !isFetchingFlairs &&
      (!isFlairRequired || selectedFlair != null);

  SubmitState copyWith({
    bool? isSubmitting,
    String? error,
    bool? success,
    List<FlairOption>? flairOptions,
    FlairOption? selectedFlair,
    bool? isFlairRequired,
    bool? isFetchingFlairs,
    bool clearError = false,
    bool clearFlairOptions = false,
  }) {
    return SubmitState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      success: success ?? this.success,
      flairOptions:
          clearFlairOptions ? const [] : (flairOptions ?? this.flairOptions),
      selectedFlair: selectedFlair ?? this.selectedFlair,
      isFlairRequired: isFlairRequired ?? this.isFlairRequired,
      isFetchingFlairs: isFetchingFlairs ?? this.isFetchingFlairs,
    );
  }
}

class SubmitNotifier extends StateNotifier<SubmitState> {
  final SubmitClient _client;
  final MediaUploadClient _mediaClient;

  /// In-memory cache of flair options keyed by subreddit name.
  final Map<String, List<FlairOption>> _flairCache = {};

  Timer? _debounceTimer;

  SubmitNotifier(this._client, this._mediaClient) : super(const SubmitState());

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Called when the subreddit text field value changes.
  ///
  /// Fetches flairs with 300ms debounce. Reuses cached results instantly.
  void onSubredditChanged(String subreddit) {
    _debounceTimer?.cancel();
    final trimmed = subreddit.trim();

    if (trimmed.isEmpty) {
      state = state.copyWith(clearFlairOptions: true, selectedFlair: null);
      return;
    }

    // Instant cache hit.
    if (_flairCache.containsKey(trimmed)) {
      state = state.copyWith(
        flairOptions: _flairCache[trimmed]!,
        selectedFlair: null,
      );
      return;
    }

    // Debounce before fetching.
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _fetchFlairs(trimmed);
    });
  }

  Future<void> _fetchFlairs(String subreddit) async {
    state = state.copyWith(isFetchingFlairs: true);
    try {
      final options = await _client.fetchFlairOptions(subreddit, null);
      _flairCache[subreddit] = options;
      state = state.copyWith(flairOptions: options, isFetchingFlairs: false);
    } catch (_) {
      state = state.copyWith(isFetchingFlairs: false, clearFlairOptions: true);
    }
  }

  void selectFlair(FlairOption? flair) {
    state = state.copyWith(selectedFlair: flair, error: null);
  }

  bool get canSubmit => state.canSubmit;

  Future<bool> submit({
    required Map<String, String> fields,
    required SessionCookie sessionCookie,
  }) async {
    if (!canSubmit) return false;

    // Capture flair before resetting state.
    final flairId = state.selectedFlair?.flairTemplateId;
    final flairText = state.selectedFlair?.text;
    state = state.copyWith(isSubmitting: true);
    try {
      if (flairId != null) {
        fields['flair_id'] = flairId;
        fields['flair_text'] = flairText ?? '';
      }
      await _client.submit(fields: fields, sessionCookie: sessionCookie);
      state = const SubmitState(success: true);
      return true;
    } catch (e) {
      state = SubmitState(error: e.toString());
      return false;
    }
  }

  void reset() => state = const SubmitState();

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
