import '../domain/enums/vote_direction.dart';
import '../domain/models/session_cookie.dart';
import 'optimistic_state_notifier.dart';
import 'reddit_client.dart';

class VoteNotifier extends OptimisticStateNotifier<String, VoteDirection> {
  final RedditClient _client;
  final SessionCookie? _sessionCookie;

  VoteNotifier(this._client, this._sessionCookie);

  Future<void> vote(String fullname, VoteDirection direction) async {
    optimisticSet(fullname, direction);
    try {
      await _client.postForm('/api/vote',
          fields: {'id': fullname, 'dir': direction.value.toString()},
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
