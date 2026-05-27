import 'write_operation_notifier.dart';

class HideNotifier extends WriteOperationNotifier<bool> {
  HideNotifier(super.redditClient, super.sessionCookie);

  @override
  bool get shouldRevertOnError => true;

  Future<void> toggle(String fullname) async {
    final previous = state[fullname];
    if (previous == true) return;
    await write(fullname, true, previous, () async {
      final sc = sessionCookie;
      if (sc == null) return;
      await redditClient.hide(fullname, sc);
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
    await redditClient.unhide(fullname, sc);
  }
}
