import '../domain/enums/vote_direction.dart';
import '../domain/models/session_cookie.dart';
import 'optimistic_state_notifier.dart';
import 'vote_repository.dart';

class VoteNotifier extends OptimisticStateNotifier<String, VoteDirection> {
  final VoteRepository _repository;
  final SessionCookie? _sessionCookie;

  VoteNotifier(this._repository, this._sessionCookie);

  Future<void> vote(String fullname, VoteDirection direction) async {
    optimisticSet(fullname, direction);
    try {
      await _repository.vote(fullname, direction.value,
          sessionCookie: _sessionCookie);
    } catch (_) {}
  }

  void toggle(String fullname, VoteDirection tappedDirection) {
    final current = state[fullname] ?? VoteDirection.none;
    final next = current == tappedDirection ? VoteDirection.none : tappedDirection;
    vote(fullname, next);
  }

  VoteDirection effectiveVote(String fullname, VoteDirection original) {
    return effective(fullname, original);
  }
}
