import 'interaction_client.dart';
import 'write_operation_notifier.dart';

class HideNotifier extends WriteOperationNotifier<bool> {
  final InteractionClient _client;

  HideNotifier(this._client, super.sessionCookie);

  Future<void> toggle(String fullname) async {
    final previous = state[fullname];
    if (previous == true) return;
    final sc = sessionCookie;
    if (sc == null) return;
    await write(fullname, true, previous, () async {
      await _client.hide(fullname, sc);
    });
  }

  void dismiss(String fullname) {
    final copy = Map<String, bool>.from(state)..remove(fullname);
    state = copy;
  }

  Future<void> unhide(String fullname) async {
    final sc = sessionCookie;
    if (sc == null) return;
    dismiss(fullname);
    await _client.unhide(fullname, sc);
  }
}
