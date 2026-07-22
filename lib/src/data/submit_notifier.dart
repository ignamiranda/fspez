import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
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

  // Media state
  final PlatformFile? selectedImage;
  final List<PlatformFile> galleryFiles;
  final List<String> galleryCaptions;
  final PlatformFile? selectedVideo;

  const SubmitState({
    this.isSubmitting = false,
    this.error,
    this.success = false,
    this.flairOptions = const [],
    this.selectedFlair,
    this.isFlairRequired = false,
    this.isFetchingFlairs = false,
    this.selectedImage,
    this.galleryFiles = const [],
    this.galleryCaptions = const [],
    this.selectedVideo,
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
    PlatformFile? selectedImage,
    bool clearImage = false,
    List<PlatformFile>? galleryFiles,
    List<String>? galleryCaptions,
    bool clearGallery = false,
    PlatformFile? selectedVideo,
    bool clearVideo = false,
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
      selectedImage: clearImage ? null : (selectedImage ?? this.selectedImage),
      galleryFiles:
          clearGallery ? const [] : (galleryFiles ?? this.galleryFiles),
      galleryCaptions:
          clearGallery ? const [] : (galleryCaptions ?? this.galleryCaptions),
      selectedVideo: clearVideo ? null : (selectedVideo ?? this.selectedVideo),
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
    } catch (e) {
      debugPrint('SubmitNotifier._fetchFlairs failed: $e');
      state = state.copyWith(isFetchingFlairs: false, clearFlairOptions: true);
    }
  }

  void selectFlair(FlairOption? flair) {
    state = state.copyWith(selectedFlair: flair, clearError: true);
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

  Future<bool> submitText({
    required String title,
    required String subreddit,
    required String text,
    required SessionCookie sessionCookie,
  }) async {
    final modhash = sessionCookie.modhash ?? '';
    final fields = <String, String>{
      'kind': 'self',
      'sr': subreddit,
      'title': title,
      'uh': modhash,
    };
    if (text.isNotEmpty) fields['text'] = text;
    return submit(fields: fields, sessionCookie: sessionCookie);
  }

  Future<bool> submitLink({
    required String title,
    required String subreddit,
    required String url,
    required SessionCookie sessionCookie,
  }) async {
    final modhash = sessionCookie.modhash ?? '';
    final fields = <String, String>{
      'kind': 'link',
      'sr': subreddit,
      'title': title,
      'uh': modhash,
    };
    if (url.isNotEmpty) fields['url'] = url;
    return submit(fields: fields, sessionCookie: sessionCookie);
  }

  void reset() => state = const SubmitState();

  // ========== Media state mutations ==========

  void setImage(PlatformFile? file) {
    state = state.copyWith(selectedImage: file);
  }

  void clearImage() {
    state = state.copyWith(clearImage: true);
  }

  void setGalleryFiles(List<PlatformFile> files) {
    state = state.copyWith(
      galleryFiles: files,
      galleryCaptions: List.filled(files.length, ''),
    );
  }

  void addGalleryImages(List<PlatformFile> files) {
    final combined = [...state.galleryFiles, ...files];
    if (combined.length > 20) return; // Hard cap
    state = state.copyWith(
      galleryFiles: combined,
      galleryCaptions: [
        ...state.galleryCaptions,
        ...List.filled(files.length, ''),
      ],
    );
  }

  void reorderGallery(int oldIndex, int newIndex) {
    final files = List<PlatformFile>.from(state.galleryFiles);
    final captions = List<String>.from(state.galleryCaptions);
    if (newIndex > oldIndex) newIndex -= 1;
    final file = files.removeAt(oldIndex);
    final caption = captions.removeAt(oldIndex);
    files.insert(newIndex, file);
    captions.insert(newIndex, caption);
    state = state.copyWith(galleryFiles: files, galleryCaptions: captions);
  }

  void removeGalleryItem(int index) {
    final files = List<PlatformFile>.from(state.galleryFiles)..removeAt(index);
    final captions = List<String>.from(state.galleryCaptions)..removeAt(index);
    state = state.copyWith(galleryFiles: files, galleryCaptions: captions);
  }

  void updateGalleryCaption(int index, String caption) {
    final captions = List<String>.from(state.galleryCaptions);
    if (index < captions.length) {
      captions[index] = caption;
      state = state.copyWith(galleryCaptions: captions);
    }
  }

  void setVideo(PlatformFile? file) {
    state = state.copyWith(selectedVideo: file);
  }

  void clearVideo() {
    state = state.copyWith(clearVideo: true);
  }

  void clearAllMedia() {
    state =
        state.copyWith(clearImage: true, clearGallery: true, clearVideo: true);
  }

  /// Upload an image and submit as a link post with the image URL.
  Future<bool> submitImage({
    required String title,
    required String subreddit,
    required PlatformFile file,
    required SessionCookie sessionCookie,
  }) async {
    state = const SubmitState(isSubmitting: true);
    try {
      if (file.path == null) throw Exception('File path is null');
      final bytes = await File(file.path!).readAsBytes();
      final media = await _mediaClient.uploadImage(
        bytes: bytes,
        filename: file.name,
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
    required PlatformFile file,
    required SessionCookie sessionCookie,
  }) async {
    state = const SubmitState(isSubmitting: true);
    try {
      if (file.path == null) throw Exception('File path is null');
      final bytes = await File(file.path!).readAsBytes();
      final media = await _mediaClient.uploadVideo(
        bytes: bytes,
        filename: file.name,
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
    required List<PlatformFile> files,
    required List<String> captions,
    required SessionCookie sessionCookie,
  }) async {
    state = const SubmitState(isSubmitting: true);
    try {
      final items = <({Uint8List bytes, String filename, String caption})>[];
      for (var i = 0; i < files.length; i++) {
        final f = files[i];
        if (f.path == null) continue;
        final bytes = await File(f.path!).readAsBytes();
        items.add((
          bytes: bytes,
          filename: f.name,
          caption: i < captions.length ? captions[i].trim() : '',
        ));
      }
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
