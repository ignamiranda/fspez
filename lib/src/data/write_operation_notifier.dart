import '../domain/models/session_cookie.dart';
import 'optimistic_state_notifier.dart';

enum WriteErrorPolicy { revert, keepOptimistic }

class WriteOperationNotifier<V>
    extends OptimisticStateNotifier<String, V> {
  final SessionCookie? sessionCookie;

  WriteOperationNotifier(this.sessionCookie);

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

  /// Reads the raw optimistic value for [key], or null if not set.
  V? peek(String key) => state[key];

  /// Returns the optimistic value if set, otherwise [original].
  V effectiveValue(String key, V original) => effective(key, original);
}
