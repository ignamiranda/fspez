import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/html_subreddit_parser.dart';

void main() {
  late HtmlSubredditParser parser;

  setUp(() {
    parser = HtmlSubredditParser();
  });

  group('parseInfo', () {
    test('returns fallback for empty HTML', () {
      final result = parser.parseInfo('', 'flutter');
      expect(result.id, '');
      expect(result.name, 'flutter');
    });

    test('parses subreddit info from embedded JSON', () {
      const html = '''
        <html>
        <script id="__NEXT_DATA__" type="application/json">
        {
          "props": {
            "pageProps": {
              "subreddit": {
                "id": "t5_2qh30",
                "displayName": "FlutterDev",
                "publicDescription": "A community for Flutter developers",
                "subscribers": 50000,
                "activeUserCount": 1200,
                "createdUtc": 1500000000,
                "over18": false,
                "userIsSubscriber": true,
                "subredditType": "public"
              }
            }
          }
        }
        </script>
        </html>
      ''';
      final result = parser.parseInfo(html, 'flutter');
      expect(result.id, 't5_2qh30');
      expect(result.name, 'FlutterDev');
      expect(result.description, 'A community for Flutter developers');
      expect(result.subscriberCount, 50000);
      expect(result.activeUserCount, 1200);
      expect(result.isSubscribed, true);
    });
  });

  group('parseRules', () {
    test('parses subreddit rules from embedded JSON', () {
      const html = '''
        <html>
        <script id="__NEXT_DATA__" type="application/json">
        {
          "props": {
            "pageProps": {
              "rules": [
                {
                  "shortName": "Rule 1",
                  "description": "Be respectful",
                  "kind": "all",
                  "priority": 1
                },
                {
                  "shortName": "Rule 2",
                  "description": "No spam",
                  "kind": "link",
                  "priority": 2
                }
              ]
            }
          }
        }
        </script>
        </html>
      ''';
      final result = parser.parseRules(html);
      expect(result.length, 2);
      expect(result[0].shortName, 'Rule 1');
      expect(result[0].description, 'Be respectful');
      expect(result[0].priority, 1);
      expect(result[1].shortName, 'Rule 2');
    });
  });
}

