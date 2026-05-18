import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/enums/vote_direction.dart';
import '../domain/models/session_cookie.dart';
import 'vote_repository.dart';

class VoteNotifier extends StateNotifier<Map<String, VoteDirection>> {
  final VoteRepository _repository;
  final SessionCookie? _sessionCookie;

  VoteNotifier(this._repository, this._sessionCookie) : super({});

  Future<void> vote(String fullname, VoteDirection direction) async {
    state = {...state, fullname: direction};
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
    return state[fullname] ?? original;
  }
}
