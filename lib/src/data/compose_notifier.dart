import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/session_cookie.dart';
import 'reddit_client.dart';

class ComposeState {
  final bool isSending;
  final String? error;
  final bool success;

  const ComposeState({
    this.isSending = false,
    this.error,
    this.success = false,
  });
}

class ComposeNotifier extends StateNotifier<ComposeState> {
  final RedditClient _client;

  ComposeNotifier(this._client) : super(const ComposeState());

  Future<bool> send({
    required Map<String, String> fields,
    required SessionCookie sessionCookie,
  }) async {
    state = const ComposeState(isSending: true);
    try {
      await _client.compose(fields: fields, sessionCookie: sessionCookie);
      state = const ComposeState(success: true);
      return true;
    } catch (e) {
      state = ComposeState(error: e.toString());
      return false;
    }
  }

  void reset() => state = const ComposeState();
}
