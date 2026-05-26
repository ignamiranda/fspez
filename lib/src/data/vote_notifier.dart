import '../domain/enums/vote_direction.dart';
import 'write_operation_notifier.dart';

class VoteNotifier extends WriteOperationNotifier<VoteDirection> {
  VoteNotifier(super.redditClient, super.sessionCookie);

  Future<void> vote(String fullname, VoteDirection direction) async {
    optimisticSet(fullname, direction);
    try {
      await redditClient.postForm('/api/vote',
          fields: {'id': fullname, 'dir': direction.value.toString()},
          sessionCookie: sessionCookie);
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
