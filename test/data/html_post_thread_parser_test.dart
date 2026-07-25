import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/html_post_thread_parser.dart';

void main() {
  late HtmlPostThreadParser parser;

  setUp(() {
    parser = HtmlPostThreadParser();
  });

  group('parse', () {
    test('returns fallback PostDetail for empty HTML', () {
      final result = parser.parse('');
      expect(result.post.title, '');
      expect(result.comments, isEmpty);
    });

    test('parses post and comments from embedded JSON', () {
      const html = '''
        <html>
        <script id="__NEXT_DATA__" type="application/json">
        {
          "props": {
            "pageProps": {
              "post": {
                "id": "abc123",
                "title": "Test Post",
                "author": "testuser",
                "subreddit": "flutter",
                "score": 42,
                "numComments": 7,
                "createdUtc": 1700000000,
                "permalink": "/r/flutter/comments/abc123/test_post/"
              },
              "comments": [
                {
                  "id": "def456",
                  "body": "Great post!",
                  "author": "commenter1",
                  "score": 10,
                  "depth": 0,
                  "createdUtc": 1700000100,
                  "linkId": "t3_abc123"
                }
              ]
            }
          }
        }
        </script>
        </html>
      ''';
      final result = parser.parse(html);
      expect(result.post.id, 'abc123');
      expect(result.post.title, 'Test Post');
      expect(result.post.author, 'testuser');
      expect(result.post.score, 42);
      expect(result.post.commentCount, 7);
      expect(result.comments.length, 1);
      expect(result.comments[0].id, 'def456');
      expect(result.comments[0].body, 'Great post!');
      expect(result.comments[0].author, 'commenter1');
      expect(result.comments[0].score, 10);
    });

    test('handles nested comment replies', () {
      const html = '''
        <html>
        <script id="__NEXT_DATA__" type="application/json">
        {
          "props": {
            "pageProps": {
              "post": {
                "id": "post1",
                "title": "Nested",
                "author": "op",
                "subreddit": "test",
                "score": 1,
                "createdUtc": 1700000000,
                "permalink": "/r/test/comments/post1/n/"
              },
              "comments": [
                {
                  "id": "c1",
                  "body": "Parent",
                  "author": "u1",
                  "score": 5,
                  "depth": 0,
                  "createdUtc": 1700000100,
                  "linkId": "t3_post1",
                  "replies": [
                    {
                      "id": "c2",
                      "body": "Reply",
                      "author": "u2",
                      "score": 3,
                      "depth": 1,
                      "createdUtc": 1700000200,
                      "linkId": "t3_post1"
                    }
                  ]
                }
              ]
            }
          }
        }
        </script>
        </html>
      ''';
      final result = parser.parse(html);
      expect(result.comments.length, 1);
      expect(result.comments[0].replies.length, 1);
      expect(result.comments[0].replies[0].body, 'Reply');
      expect(result.comments[0].replies[0].depth, 1);
    });

    test('parses vote direction from likes field', () {
      const html = '''
        <html>
        <script id="__NEXT_DATA__" type="application/json">
        {
          "props": {
            "pageProps": {
              "post": {
                "id": "post1",
                "title": "Voted",
                "author": "user",
                "subreddit": "test",
                "score": 10,
                "likes": true,
                "createdUtc": 1700000000,
                "permalink": "/r/test/comments/post1/v/"
              }
            }
          }
        }
        </script>
        </html>
      ''';
      final result = parser.parse(html);
      expect(result.post.vote.index, 0); // VoteDirection.upvote
    });
  });
}

