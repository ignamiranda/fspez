import '../domain/models/session_cookie.dart';
import 'optimistic_state_notifier.dart';
import 'reddit_client.dart';

enum WriteErrorPolicy { revert, keepOptimistic }

abstract class WriteOperationNotifier<V>
    extends OptimisticStateNotifier<String, V> {
  final RedditClient redditClient;
  final SessionCookie? sessionCookie;

  WriteOperationNotifier(this.redditClient, this.sessionCookie);

  Future<void> write(
    String key,
    V optimisticValue,
    V? previousValue,
    Future<void> Function() apiCall, {
    WriteErrorPolicy onError = WriteErrorPolicy.revert,
  }) async {
    optimisticSet(key, optimisticValue);
    try {
      await apiCall();
    } catch (e) {
      if (onError == WriteErrorPolicy.revert) {
        optimisticRevert(key, previousValue);
      }
      rethrow;
    }
  }
}
