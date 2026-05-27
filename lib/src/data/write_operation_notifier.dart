import '../domain/models/session_cookie.dart';
import 'optimistic_state_notifier.dart';
import 'reddit_client.dart';

abstract class WriteOperationNotifier<V>
    extends OptimisticStateNotifier<String, V> {
  final RedditClient redditClient;
  final SessionCookie? sessionCookie;

  WriteOperationNotifier(this.redditClient, this.sessionCookie);

  bool get shouldRevertOnError => true;

  Future<void> write(
    String key,
    V optimisticValue,
    V? previousValue,
    Future<void> Function() apiCall,
  ) async {
    optimisticSet(key, optimisticValue);
    try {
      await apiCall();
    } catch (e) {
      if (shouldRevertOnError) {
        optimisticRevert(key, previousValue);
      }
      rethrow;
    }
  }
}
