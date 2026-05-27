import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/session_cookie.dart';
import 'reddit_client.dart';

class EditState {
  final bool isSaving;
  final String? error;
  final bool success;

  const EditState({
    this.isSaving = false,
    this.error,
    this.success = false,
  });
}

class EditNotifier extends StateNotifier<EditState> {
  final RedditClient _client;

  EditNotifier(this._client) : super(const EditState());

  String? get error => state.error;

  Future<bool> edit(String thingId, String text, SessionCookie cookie) async {
    state = const EditState(isSaving: true);
    try {
      await _client.editContent(thingId: thingId, text: text, sessionCookie: cookie);
      state = const EditState(success: true);
      return true;
    } catch (e) {
      state = EditState(error: e.toString());
      return false;
    }
  }

  void reset() => state = const EditState();
}
