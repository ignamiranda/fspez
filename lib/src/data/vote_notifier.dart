import 'package:flutter/foundation.dart';
import '../domain/enums/vote_direction.dart';
import 'write_operation_notifier.dart';

class VoteNotifier extends WriteOperationNotifier<VoteDirection> {
  VoteNotifier(super.redditClient, super.sessionCookie);

  Future<void> vote(String fullname, VoteDirection direction) async {
    final previous = state[fullname];
    try {
      await write(
        fullname,
        direction,
        previous,
        () => redditClient.postForm('/api/vote',
            fields: {'id': fullname, 'dir': direction.value.toString()},
            sessionCookie: sessionCookie),
        onError: WriteErrorPolicy.keepOptimistic,
      );
    } catch (e) {
      debugPrint('VoteNotifier.vote failed: $e');
    }
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
