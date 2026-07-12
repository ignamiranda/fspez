class ParsedCommentContext {
  final String subreddit;
  final String postId;
  final String commentId;

  const ParsedCommentContext({
    required this.subreddit,
    required this.postId,
    required this.commentId,
  });
}

ParsedCommentContext? parseCommentContext(String? context) {
  if (context == null || context.isEmpty) return null;

  var url = context;
  if (!url.startsWith('http://') && !url.startsWith('https://') && !url.startsWith('/')) {
    url = 'https://$url';
  }

  final uri = Uri.tryParse(url);
  if (uri == null) return null;

  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

  final commentsIdx = segments.indexOf('comments');
  if (commentsIdx == -1) return null;

  final afterComments = segments.length - commentsIdx - 1;
  if (afterComments < 2) return null;

  final postId = segments[commentsIdx + 1];
  final commentId = segments.last;

  var subreddit = '';
  for (var i = 0; i < commentsIdx && i < segments.length; i++) {
    if (segments[i] != 'r') {
      subreddit = segments[i];
      break;
    }
  }

  return ParsedCommentContext(
    subreddit: subreddit,
    postId: postId,
    commentId: commentId,
  );
}
