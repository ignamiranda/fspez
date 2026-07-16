/// Endpoint variants that determine HTTP headers and URL construction
/// in [HttpTransport].
enum ApiEndpoint {
  json,
  form,
  oldReddit,
  comment,
  submit,
  compose,
  mediaUpload,
}

/// Exception thrown when a Reddit API request returns a non-success status
/// code or encounters a protocol-level error.
class RedditApiException implements Exception {
  final int statusCode;
  final String message;

  const RedditApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'RedditApiException($statusCode): $message';
}
