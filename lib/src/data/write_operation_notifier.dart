import '../domain/models/session_cookie.dart';
import 'optimistic_state_notifier.dart';
import 'reddit_client.dart';

abstract class WriteOperationNotifier<V>
    extends OptimisticStateNotifier<String, V> {
  final RedditClient redditClient;
  final SessionCookie? sessionCookie;

  WriteOperationNotifier(this.redditClient, this.sessionCookie);
}
