import '../domain/models/session_cookie.dart';
import 'optimistic_state_notifier.dart';
import 'reddit_client.dart';

class SaveException implements Exception {
  final int statusCode;
  final String body;
  const SaveException({required this.statusCode, required this.body});
  @override
  String toString() => 'SaveException($statusCode): ${body.length > 200 ? body.substring(0, 200) : body}';
}

class SaveNotifier extends OptimisticStateNotifier<String, bool> {
  final RedditClient _client;
  final SessionCookie? _sessionCookie;

  SaveNotifier(this._client, this._sessionCookie);

  Future<void> toggle(String fullname) async {
    final current = state[fullname] ?? false;
    final next = !current;
    optimisticSet(fullname, next);
    try {
      if (_sessionCookie == null) throw const SaveException(statusCode: 0, body: 'No session');
      final sc = _sessionCookie;
      if (next) {
        await _client.save(fullname, sc);
      } else {
        await _client.unsave(fullname, sc);
      }
    } on RedditApiException catch (e) {
      optimisticRevert(fullname, current);
      throw SaveException(statusCode: e.statusCode, body: e.message);
    } catch (_) {
      optimisticRevert(fullname, current);
      rethrow;
    }
  }

  bool effectiveSaved(String fullname, bool original) {
    return effective(fullname, original);
  }
}