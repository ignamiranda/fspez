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

  @override
  bool get shouldRevertOnError => true;

  Future<void> toggle(String fullname) async {
    final current = state[fullname] ?? false;
    final next = !current;
    final sc = sessionCookie;
    if (sc == null) {
      state = {...state, fullname: current};
      throw const SaveException(statusCode: 0, body: 'No session');
    }
    try {
      await write(fullname, next, current, () async {
        if (next) {
          await redditClient.save(fullname, sc);
        } else {
          await redditClient.unsave(fullname, sc);
        }
      });
    } on RedditApiException catch (e) {
      throw SaveException(statusCode: e.statusCode, body: e.message);
    }
  }

  bool effectiveSaved(String fullname, bool original) {
    return effective(fullname, original);
  }
}
