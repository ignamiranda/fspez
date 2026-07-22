import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/session_cookie.dart';
import 'message_client.dart';
import 'write_notifier.dart';

class ComposeNotifier extends StateNotifier<WriteState> {
  final MessageClient _client;

  ComposeNotifier(this._client) : super(const WriteState());

  Future<bool> send({
    required Map<String, String> fields,
    required SessionCookie sessionCookie,
  }) async {
    state = const WriteState(isProcessing: true);
    try {
      await _client.compose(fields: fields, sessionCookie: sessionCookie);
      state = const WriteState(success: true);
      return true;
    } catch (e) {
      state = WriteState(error: e.toString());
      return false;
    }
  }

  void reset() => state = const WriteState();
}
