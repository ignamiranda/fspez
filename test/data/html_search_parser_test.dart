import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/html_search_parser.dart';

void main() {
  late HtmlSearchParser parser;

  setUp(() {
    parser = HtmlSearchParser();
  });

  group('parsePosts', () {
    test('returns empty feed for empty HTML', () {
      final result = parser.parsePosts('');
      expect(result.posts, isEmpty);
    });

    test('parses search results from embedded JSON', () {
      const html = '''
        <html>
        <script id="__NEXT_DATA__" type="application/json">
        {
          "props": {
            "pageProps": {
              "posts": [
                {
                  "id": "post1",
                  "title": "Search Result 1",
                  "author": "user1",
                  "subreddit": "flutter",
                  "score": 42,
                  "numComments": 7,
                  "createdUtc": 1700000000,
                  "permalink": "/r/flutter/comments/post1/title/"
                },
                {
                  "id": "post2",
                  "title": "Search Result 2",
                  "author": "user2",
                  "subreddit": "dartlang",
                  "score": 10,
                  "numComments": 3,
                  "createdUtc": 1700001000,
                  "permalink": "/r/dartlang/comments/post2/title/"
                }
              ]
            }
          }
        }
        </script>
        </html>
      ''';
      final result = parser.parsePosts(html);
      expect(result.posts.length, 2);
      expect(result.posts[0].title, 'Search Result 1');
      expect(result.posts[0].score, 42);
      expect(result.posts[1].subreddit.name, 'dartlang');
    });
  });

  group('parseUsers', () {
    test('parses user search results', () {
      const html = '''
        <html>
        <script id="__NEXT_DATA__" type="application/json">
        {
          "props": {
            "pageProps": {
              "users": [
                {
                  "name": "founduser",
                  "linkKarma": 500,
                  "commentKarma": 300,
                  "isGold": true
                }
              ]
            }
          }
        }
        </script>
        </html>
      ''';
      final result = parser.parseUsers(html);
      expect(result.length, 1);
      expect(result[0].name, 'founduser');
      expect(result[0].linkKarma, 500);
      expect(result[0].commentKarma, 300);
      expect(result[0].isGold, true);
    });
  });

  group('parseCommunities', () {
    test('parses community search results', () {
      const html = '''
        <html>
        <script id="__NEXT_DATA__" type="application/json">
        {
          "props": {
            "pageProps": {
              "subreddits": [
                {
                  "id": "t5_test",
                  "displayName": "TestSubreddit",
                  "subscribers": 1000
                }
              ]
            }
          }
        }
        </script>
        </html>
      ''';
      final result = parser.parseCommunities(html);
      expect(result.length, 1);
      expect(result[0].name, 'TestSubreddit');
      expect(result[0].subscriberCount, 1000);
    });
  });
}

