import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/flair_option.dart';
import 'submit_client.dart';

class FlairState {
  final List<FlairOption> flairOptions;
  final FlairOption? selectedFlair;
  final bool isFlairRequired;
  final bool isFetchingFlairs;

  const FlairState({
    this.flairOptions = const [],
    this.selectedFlair,
    this.isFlairRequired = false,
    this.isFetchingFlairs = false,
  });

  FlairState copyWith({
    List<FlairOption>? flairOptions,
    FlairOption? selectedFlair,
    bool? isFlairRequired,
    bool? isFetchingFlairs,
    bool clearFlairOptions = false,
    bool clearSelectedFlair = false,
  }) {
    return FlairState(
      flairOptions:
          clearFlairOptions ? const [] : (flairOptions ?? this.flairOptions),
      selectedFlair:
          clearSelectedFlair ? null : (selectedFlair ?? this.selectedFlair),
      isFlairRequired: isFlairRequired ?? this.isFlairRequired,
      isFetchingFlairs: isFetchingFlairs ?? this.isFetchingFlairs,
    );
  }
}

class FlairNotifier extends StateNotifier<FlairState> {
  final SubmitClient _client;

  final Map<String, List<FlairOption>> _flairCache = {};

  Timer? _debounceTimer;

  FlairNotifier(this._client) : super(const FlairState());

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void onSubredditChanged(String subreddit) {
    _debounceTimer?.cancel();
    final trimmed = subreddit.trim();

    if (trimmed.isEmpty) {
      state = state.copyWith(clearFlairOptions: true, clearSelectedFlair: true);
      return;
    }

    if (_flairCache.containsKey(trimmed)) {
      state = state.copyWith(
        flairOptions: _flairCache[trimmed]!,
        clearSelectedFlair: true,
      );
      return;
    }

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
      debugPrint('FlairNotifier._fetchFlairs failed: $e');
      state = state.copyWith(isFetchingFlairs: false, clearFlairOptions: true);
    }
  }

  void selectFlair(FlairOption? flair) {
    if (flair == null) {
      state = state.copyWith(clearSelectedFlair: true);
    } else {
      state = state.copyWith(selectedFlair: flair);
    }
  }

  void reset() {
    state = const FlairState();
  }
}
