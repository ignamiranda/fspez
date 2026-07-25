import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/html_user_profile_parser.dart';

void main() {
  late HtmlUserProfileParser parser;

  setUp(() {
    parser = HtmlUserProfileParser();
  });

  group('parseProfile', () {
    test('returns fallback for empty HTML', () {
      final result = parser.parseProfile('', 'testuser');
      expect(result.id, '');
      expect(result.username, 'testuser');
    });

    test('parses user profile from embedded JSON', () {
      const html = '''
        <html>
        <script id="__NEXT_DATA__" type="application/json">
        {
          "props": {
            "pageProps": {
              "user": {
                "id": "t2_user1",
                "name": "reddituser",
                "linkKarma": 100,
                "commentKarma": 200,
                "createdUtc": 1600000000,
                "isGold": true,
                "isMod": false
              }
            }
          }
        }
        </script>
        </html>
      ''';
      final result = parser.parseProfile(html, 'fallback');
      expect(result.id, 't2_user1');
      expect(result.username, 'reddituser');
      expect(result.linkKarma, 100);
      expect(result.commentKarma, 200);
      expect(result.isGold, true);
      expect(result.isMod, false);
    });

    test('parses user comments', () {
      const html = '''
        <html>
        <script id="__NEXT_DATA__" type="application/json">
        {
          "props": {
            "pageProps": {
              "comments": [
                {
                  "id": "c1",
                  "body": "User comment",
                  "author": "reddituser",
                  "score": 15,
                  "createdUtc": 1700000000,
                  "linkId": "t3_post1",
                  "subreddit": "flutter"
                }
              ]
            }
          }
        }
        </script>
        </html>
      ''';
      final comments = parser.parseComments(html);
      expect(comments.length, 1);
      expect(comments[0].id, 'c1');
      expect(comments[0].body, 'User comment');
      expect(comments[0].score, 15);
      expect(comments[0].subreddit, 'flutter');
    });
  });
}

