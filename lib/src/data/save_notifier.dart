import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/session_cookie.dart';
import 'save_repository.dart';

class SaveNotifier extends StateNotifier<Map<String, bool>> {
  final SaveRepository _repository;
  final SessionCookie? _sessionCookie;

  SaveNotifier(this._repository, this._sessionCookie) : super({});

  Future<void> toggle(String fullname) async {
    final current = state[fullname] ?? false;
    final next = !current;
    state = {...state, fullname: next};
    try {
      if (next) {
        await _repository.save(fullname, sessionCookie: _sessionCookie);
      } else {
        await _repository.unsave(fullname, sessionCookie: _sessionCookie);
      }
    } on SaveException {
      state = {...state, fullname: current};
      rethrow;
    } catch (_) {
      state = {...state, fullname: current};
      rethrow;
    }
  }

  bool effectiveSaved(String fullname, bool original) {
    return state[fullname] ?? original;
  }
}
