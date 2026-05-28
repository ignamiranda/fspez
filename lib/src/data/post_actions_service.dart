import '../domain/enums/vote_direction.dart';
import '../domain/models/session_cookie.dart';
import 'delete_notifier.dart';
import 'edit_notifier.dart';
import 'hide_notifier.dart';
import 'save_notifier.dart';
import 'vote_notifier.dart';

class PostActionsService {
  final VoteNotifier _voteNotifier;
  final SaveNotifier _saveNotifier;
  final HideNotifier _hideNotifier;
  final DeleteNotifier _deleteNotifier;
  final EditNotifier _editNotifier;
  final SessionCookie? _sessionCookie;

  const PostActionsService({
    required VoteNotifier voteNotifier,
    required SaveNotifier saveNotifier,
    required HideNotifier hideNotifier,
    required DeleteNotifier deleteNotifier,
    required EditNotifier editNotifier,
    required SessionCookie? sessionCookie,
  })  : _voteNotifier = voteNotifier,
        _saveNotifier = saveNotifier,
        _hideNotifier = hideNotifier,
        _deleteNotifier = deleteNotifier,
        _editNotifier = editNotifier,
        _sessionCookie = sessionCookie;

  String? get editError => _editNotifier.error;

  void vote(String fullname, VoteDirection direction) {
    _voteNotifier.toggle(fullname, direction);
  }

  Future<void> toggleSave(String fullname) {
    return _saveNotifier.toggle(fullname);
  }

  Future<void> hide(String fullname) {
    return _hideNotifier.toggle(fullname);
  }

  Future<void> unhide(String fullname) {
    return _hideNotifier.unhide(fullname);
  }

  Future<void> delete(String fullname) {
    final cookie = _sessionCookie;
    if (cookie == null) {
      throw const PostActionException('No session');
    }
    return _deleteNotifier.delete(fullname, cookie);
  }

  Future<bool> edit(String thingId, String text) {
    final cookie = _sessionCookie;
    if (cookie == null) return Future.value(false);
    return _editNotifier.edit(thingId, text, cookie);
  }
}

class PostActionException implements Exception {
  final String message;

  const PostActionException(this.message);

  @override
  String toString() => 'PostActionException: $message';
}
