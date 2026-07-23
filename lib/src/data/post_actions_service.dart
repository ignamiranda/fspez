import '../domain/enums/vote_direction.dart';
import '../domain/models/session_cookie.dart';
import 'edit_notifier.dart';
import 'interaction_client.dart';
import 'write_operation_notifier.dart';

class PostActionsService {
  final WriteOperationNotifier<VoteDirection> _voteNotifier;
  final WriteOperationNotifier<bool> _saveNotifier;
  final WriteOperationNotifier<bool> _hideNotifier;
  final WriteOperationNotifier<void> _deleteNotifier;
  final EditNotifier _editNotifier;
  final InteractionClient _client;
  final SessionCookie _sessionCookie;

  PostActionsService({
    required WriteOperationNotifier<VoteDirection> voteNotifier,
    required WriteOperationNotifier<bool> saveNotifier,
    required WriteOperationNotifier<bool> hideNotifier,
    required WriteOperationNotifier<void> deleteNotifier,
    required EditNotifier editNotifier,
    required InteractionClient client,
    required SessionCookie sessionCookie,
  })  : _voteNotifier = voteNotifier,
        _saveNotifier = saveNotifier,
        _hideNotifier = hideNotifier,
        _deleteNotifier = deleteNotifier,
        _editNotifier = editNotifier,
        _client = client,
        _sessionCookie = sessionCookie;

  Future<void> vote(String fullname, VoteDirection direction) {
    final current = _voteNotifier.effective(fullname, VoteDirection.none);
    final next = current == direction ? VoteDirection.none : direction;
    final sc = _sessionCookie;
    return _voteNotifier
        .write(
          fullname,
          next,
          current,
          () => _client.vote(
            fullname: fullname,
            direction: next.value,
            sessionCookie: sc,
          ),
          onError: WriteErrorPolicy.keepOptimistic,
        )
        .catchError((_) {});
  }

  Future<void> toggleSave(String fullname) async {
    final current = _saveNotifier.effectiveValue(fullname, false);
    final next = !current;
    final sc = _sessionCookie;
    try {
      await _saveNotifier.write(fullname, next, current, () async {
        if (next) {
          await _client.save(fullname, sc);
        } else {
          await _client.unsave(fullname, sc);
        }
      });
    } catch (e) {
      throw PostActionException('Save failed: $e');
    }
  }

  Future<void> hide(String fullname) async {
    final sc = _sessionCookie;
    final current = _hideNotifier.effectiveValue(fullname, false);
    await _hideNotifier.write(fullname, true, current,
        () => _client.hide(fullname, sc));
  }

  Future<void> unhide(String fullname) async {
    final sc = _sessionCookie;
    final current = _hideNotifier.effectiveValue(fullname, true);
    await _hideNotifier.write(fullname, false, current,
        () => _client.unhide(fullname, sc));
  }

  Future<void> delete(String fullname) async {
    final sc = _sessionCookie;
    await _deleteNotifier.write(
        fullname, null, null, () => _client.deleteContent(fullname, sc));
  }

  Future<void> edit(String thingId, String text) async {
    final success = await _editNotifier.edit(thingId, text, _sessionCookie);
    if (!success) {
      throw PostActionException(_editNotifier.error ?? 'Edit failed');
    }
  }
}

class PostActionException implements Exception {
  final String message;
  const PostActionException(this.message);
  @override
  String toString() => 'PostActionException: $message';
}
