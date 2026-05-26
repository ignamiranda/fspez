import 'reddit_client.dart';
import 'write_operation_notifier.dart';

class SaveException implements Exception {
  final int statusCode;
  final String body;
  const SaveException({required this.statusCode, required this.body});
  @override
  String toString() => 'SaveException($statusCode): ${body.length > 200 ? body.substring(0, 200) : body}';
}

class SaveNotifier extends WriteOperationNotifier<bool> {
  SaveNotifier(super.redditClient, super.sessionCookie);

  Future<void> toggle(String fullname) async {
    final current = state[fullname] ?? false;
    final next = !current;
    optimisticSet(fullname, next);
    try {
      final sc = sessionCookie;
      if (sc == null) throw const SaveException(statusCode: 0, body: 'No session');
      if (next) {
        await redditClient.save(fullname, sc);
      } else {
        await redditClient.unsave(fullname, sc);
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