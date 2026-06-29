import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/flair_option.dart';
import '../domain/models/session_cookie.dart';
import 'reddit_client.dart';

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
  final RedditClient _client;

  /// In-memory cache of flair options keyed by subreddit name.
  final Map<String, List<FlairOption>> _flairCache = {};

  Timer? _debounceTimer;

  SubmitNotifier(this._client) : super(const SubmitState());

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

    state = const SubmitState(isSubmitting: true);
    try {
      if (state.selectedFlair != null) {
        fields['flair_id'] = state.selectedFlair!.flairTemplateId;
        fields['flair_text'] = state.selectedFlair!.text;
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
}
