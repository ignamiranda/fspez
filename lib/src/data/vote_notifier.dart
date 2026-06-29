import 'package:flutter/foundation.dart';
import '../domain/enums/vote_direction.dart';
import 'interaction_client.dart';
import 'write_operation_notifier.dart';

class VoteNotifier extends WriteOperationNotifier<VoteDirection> {
  final InteractionClient _client;

  VoteNotifier(this._client, super.sessionCookie);

  Future<void> vote(String fullname, VoteDirection direction) async {
    final previous = state[fullname];
    final sc = sessionCookie;
    if (sc == null) return;
    try {
      await write(
        fullname,
        direction,
        previous,
        () => _client.vote(
          fullname: fullname,
          direction: direction.value,
          sessionCookie: sc,
        ),
        onError: WriteErrorPolicy.keepOptimistic,
      );
    } catch (e) {
      debugPrint('VoteNotifier.vote failed: $e');
    }
  }

  void toggle(String fullname, VoteDirection tappedDirection) {
    final current = state[fullname] ?? VoteDirection.none;
    final next =
        current == tappedDirection ? VoteDirection.none : tappedDirection;
    vote(fullname, next);
  }

  VoteDirection effectiveVote(String fullname, VoteDirection original) {
    return effective(fullname, original);
  }
}
