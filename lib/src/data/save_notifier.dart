import '../domain/models/session_cookie.dart';
import 'optimistic_state_notifier.dart';
import 'save_repository.dart';

class SaveNotifier extends OptimisticStateNotifier<String, bool> {
  final SaveRepository _repository;
  final SessionCookie? _sessionCookie;

  SaveNotifier(this._repository, this._sessionCookie);

  Future<void> toggle(String fullname) async {
    final current = state[fullname] ?? false;
    final next = !current;
    optimisticSet(fullname, next);
    try {
      if (next) {
        await _repository.save(fullname, sessionCookie: _sessionCookie);
      } else {
        await _repository.unsave(fullname, sessionCookie: _sessionCookie);
      }
    } catch (_) {
      optimisticRevert(fullname, current);
      rethrow;
    }
  }

  bool effectiveSaved(String fullname, bool original) {
    return effective(fullname, original);
  }
}
