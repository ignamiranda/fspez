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
