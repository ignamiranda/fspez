import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Generic state for one-shot write operations (compose, edit, submit, etc.).
class WriteState {
  final bool isProcessing;
  final String? error;
  final bool success;

  const WriteState({
    this.isProcessing = false,
    this.error,
    this.success = false,
  });

  WriteState copyWith({bool? isProcessing, String? error, bool? success}) {
    return WriteState(
      isProcessing: isProcessing ?? this.isProcessing,
      error: error ?? this.error,
      success: success ?? this.success,
    );
  }
}

/// Base notifier for one-shot write operations.
///
/// Provides the standard execute()->reset() lifecycle that ADR-0004 prescribes:
///   set isProcessing -> call API -> success/error -> reset.
abstract class WriteNotifier extends StateNotifier<WriteState> {
  WriteNotifier() : super(const WriteState());

  /// Executes [call] with the standard processing→success/error lifecycle.
  /// Returns true on success, false on error.
  Future<bool> execute(Future<void> Function() call) async {
    state = const WriteState(isProcessing: true);
    try {
      await call();
      state = const WriteState(success: true);
      return true;
    } catch (e) {
      state = WriteState(error: e.toString());
      return false;
    }
  }

  void reset() => state = const WriteState();
}
