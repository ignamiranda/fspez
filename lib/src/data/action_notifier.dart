import 'write_operation_notifier.dart';

/// Concrete, reusable action notifier for one-shot Reddit operations.
///
/// Replaces VoteNotifier, SaveNotifier, HideNotifier, DeleteNotifier.
/// Keeps the WriteOperationNotifier pattern but removes the per-file subclass boilerplate.
class ActionNotifier<V> extends WriteOperationNotifier<V> {
  ActionNotifier(super.redditClient, super.sessionCookie);

  V effectiveValue(String key, V original) => effective(key, original);

  /// Raw state accessor for [key], or null if not set.
  /// Used by PostActionsService to build previousValue for write().
  V? peek(String key) => state[key];
}
