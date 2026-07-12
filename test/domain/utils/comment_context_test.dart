import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/domain/utils/comment_context.dart';

void main() {
  group('parseCommentContext', () {
    test('returns null for null input', () {
      expect(parseCommentContext(null), isNull);
    });

    test('returns null for empty string', () {
      expect(parseCommentContext(''), isNull);
    });

    test('returns null for malformed URL', () {
      expect(parseCommentContext('not-a-url'), isNull);
    });

    test('returns null when path has no /comments/', () {
      expect(
        parseCommentContext('/r/subreddit/something/postId/commentId/'),
        isNull,
      );
    });

    test('returns null when after /comments/ has insufficient segments', () {
      expect(
        parseCommentContext('/r/subreddit/comments/postId/'),
        isNull,
      );
    });

    test('parses relative context URL', () {
      final result = parseCommentContext(
        '/r/subreddit/comments/postId/commentId/',
      );
      expect(result, isNotNull);
      expect(result!.subreddit, 'subreddit');
      expect(result.postId, 'postId');
      expect(result.commentId, 'commentId');
    });

    test('parses full context URL', () {
      final result = parseCommentContext(
        'https://www.reddit.com/r/subreddit/comments/postId/commentId/',
      );
      expect(result, isNotNull);
      expect(result!.subreddit, 'subreddit');
      expect(result.postId, 'postId');
      expect(result.commentId, 'commentId');
    });

    test('parses context URL with trailing slash on domain', () {
      final result = parseCommentContext(
        'https://www.reddit.com/r/subreddit/comments/postId/commentId/',
      );
      expect(result, isNotNull);
      expect(result!.subreddit, 'subreddit');
    });

    test('parses context URL with multi-part subreddit name', () {
      final result = parseCommentContext(
        '/r/subreddit_name/comments/postId/commentId/',
      );
      expect(result, isNotNull);
      expect(result!.subreddit, 'subreddit_name');
      expect(result.postId, 'postId');
      expect(result.commentId, 'commentId');
    });

    test('parses context URL without leading slash', () {
      final result = parseCommentContext(
        'r/subreddit/comments/postId/commentId/',
      );
      expect(result, isNotNull);
      expect(result!.subreddit, 'subreddit');
      expect(result.postId, 'postId');
      expect(result.commentId, 'commentId');
    });
  });
}
