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

    test('strips t3_ prefix from postId', () {
      final result = parseCommentContext(
        '/r/subreddit/comments/t3_abc123/title/def456/',
      );
      expect(result, isNotNull);
      expect(result!.postId, 'abc123');
      expect(result.commentId, 'def456');
    });

    test('strips t1_ prefix from commentId', () {
      final result = parseCommentContext(
        '/r/subreddit/comments/abc123/title/t1_def456/',
      );
      expect(result, isNotNull);
      expect(result!.postId, 'abc123');
      expect(result.commentId, 'def456');
    });

    test('strips both t3_ and t1_ prefixes', () {
      final result = parseCommentContext(
        '/r/subreddit/comments/t3_abc123/title/t1_def456/',
      );
      expect(result, isNotNull);
      expect(result!.postId, 'abc123');
      expect(result.commentId, 'def456');
    });

    test('parses Reddit example with t3_ prefix', () {
      final result = parseCommentContext(
        'https://www.reddit.com/comments/t3_1uy0q6u/_/oxvhgzd/',
      );
      expect(result, isNotNull);
      expect(result!.postId, '1uy0q6u');
      expect(result.commentId, 'oxvhgzd');
      expect(result.subreddit, '');
    });

    test('parses context URL with query parameter', () {
      final result = parseCommentContext(
        '/r/subreddit/comments/abc123/title/def456/?context=3',
      );
      expect(result, isNotNull);
      expect(result!.postId, 'abc123');
      expect(result.commentId, 'def456');
    });
  });
}
