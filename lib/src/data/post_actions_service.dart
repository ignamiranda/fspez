import '../domain/enums/vote_direction.dart';
import '../domain/models/session_cookie.dart';
import 'action_notifier.dart';
import 'edit_notifier.dart';
import 'write_operation_notifier.dart';

class PostActionsService {
  final ActionNotifier<VoteDirection> _voteNotifier;
  final ActionNotifier<bool> _saveNotifier;
  final ActionNotifier<bool> _hideNotifier;
  final ActionNotifier<void> _deleteNotifier;
  final EditNotifier _editNotifier;
  final SessionCookie _sessionCookie;

  const PostActionsService({
    required ActionNotifier<VoteDirection> voteNotifier,
    required ActionNotifier<bool> saveNotifier,
    required ActionNotifier<bool> hideNotifier,
    required ActionNotifier<void> deleteNotifier,
    required EditNotifier editNotifier,
    required SessionCookie sessionCookie,
  })  : _voteNotifier = voteNotifier,
        _saveNotifier = saveNotifier,
        _hideNotifier = hideNotifier,
        _deleteNotifier = deleteNotifier,
        _editNotifier = editNotifier,
        _sessionCookie = sessionCookie;

  void vote(String fullname, VoteDirection direction) {
    final current = _voteNotifier.effective(fullname, VoteDirection.none);
    final next = current == direction ? VoteDirection.none : direction;
    final sc = _sessionCookie;
    _voteNotifier.write(
      fullname,
      next,
      current,
      () => _voteNotifier.redditClient.postForm('/api/vote',
          fields: {'id': fullname, 'dir': next.value.toString()},
          sessionCookie: sc),
      onError: WriteErrorPolicy.keepOptimistic,
    ).catchError((_) {}); // Vote failure is non-critical — swallow.
  }

  Future<void> toggleSave(String fullname) async {
    final current = _saveNotifier.peek(fullname) ?? false;
    final next = !current;
    final sc = _sessionCookie;
    try {
      await _saveNotifier.write(fullname, next, current, () async {
        if (next) {
          await _saveNotifier.redditClient.save(fullname, sc);
        } else {
          await _saveNotifier.redditClient.unsave(fullname, sc);
        }
      });
    } catch (e) {
      throw PostActionException('Save failed: $e');
    }
  }

  Future<void> hide(String fullname) async {
    final sc = _sessionCookie;
    await _hideNotifier.write(fullname, true, _hideNotifier.peek(fullname),
      () => _hideNotifier.redditClient.hide(fullname, sc));
  }

  Future<void> unhide(String fullname) async {
    final sc = _sessionCookie;
    await _hideNotifier.redditClient.unhide(fullname, sc);
  }

  Future<void> delete(String fullname) async {
    final sc = _sessionCookie;
    await _deleteNotifier.write(fullname, null, null,
      () => _deleteNotifier.redditClient.deleteContent(fullname, sc));
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
