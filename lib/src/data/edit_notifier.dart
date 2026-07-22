import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/session_cookie.dart';
import 'interaction_client.dart';
import 'write_notifier.dart';

class EditNotifier extends StateNotifier<WriteState> {
  final InteractionClient _client;

  EditNotifier(this._client) : super(const WriteState());

  String? get error => state.error;

  Future<bool> edit(String thingId, String text, SessionCookie cookie) async {
    state = const WriteState(isProcessing: true);
    try {
      await _client.editContent(
          thingId: thingId, text: text, sessionCookie: cookie);
      state = const WriteState(success: true);
      return true;
    } catch (e) {
      state = WriteState(error: e.toString());
      return false;
    }
  }

  void reset() => state = const WriteState();
}
