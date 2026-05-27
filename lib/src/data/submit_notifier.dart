import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/session_cookie.dart';
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

  SubmitNotifier(this._client) : super(const SubmitState());

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
}
