import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/reddit_client.dart';
import 'package:fspez/src/data/subreddit_repository.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class _MockHttpClient extends Mock implements http.Client {}

String _withNextData(String jsonBody) {
  return '''
    <html>
    <script id="__NEXT_DATA__" type="application/json">$jsonBody</script>
    </html>
  ''';
}

void main() {
  late _MockHttpClient mockHttp;
  late SubredditRepository repository;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    mockHttp = _MockHttpClient();
    repository = SubredditRepository(RedditClient(httpClient: mockHttp));
  });

  test('fetch parses subreddit about details from HTML', () async {
    when(() => mockHttp.get(any(), headers: any(named: 'headers'))).thenAnswer(
      (_) async => http.Response(
        _withNextData('''
          {
            "props": {
              "pageProps": {
                "subreddit": {
                  "id": "2qh33",
                  "displayName": "flutter",
                  "publicDescription": "Flutter community",
                  "description": "Long sidebar text",
                  "subscribers": 123456,
                  "activeUserCount": 789,
                  "createdUtc": 1200000000,
                  "over18": true,
                  "quarantine": true,
                  "userIsSubscriber": true,
                  "subredditType": "restricted",
                  "iconImg": "https://example.com/icon.png?x=1&amp;y=2",
                  "bannerImg": "https://example.com/banner.png"
                }
              }
            }
          }
        '''),
        200,
      ),
    );

    final subreddit = await repository.fetch('flutter');

    expect(subreddit.id, '2qh33');
    expect(subreddit.name, 'flutter');
    expect(subreddit.description, 'Flutter community');
    expect(subreddit.sidebarDescription, 'Long sidebar text');
    expect(subreddit.subscriberCount, 123456);
    expect(subreddit.activeUserCount, 789);
    expect(subreddit.createdAt,
        DateTime.fromMillisecondsSinceEpoch(1200000000 * 1000));
    expect(subreddit.isNsfw, isTrue);
    expect(subreddit.isQuarantined, isTrue);
    expect(subreddit.isSubscribed, isTrue);
    expect(subreddit.isRestricted, isTrue);
    expect(subreddit.iconUrl, 'https://example.com/icon.png?x=1&y=2');
    expect(subreddit.bannerUrl, 'https://example.com/banner.png');

    verify(
      () => mockHttp.get(
        Uri.parse('https://www.reddit.com/r/flutter/about'),
        headers: any(named: 'headers'),
      ),
    ).called(1);
  });

  test('fetchRules parses and sorts subreddit rules from HTML', () async {
    when(() => mockHttp.get(any(), headers: any(named: 'headers'))).thenAnswer(
      (_) async => http.Response(
        _withNextData('''
          {
            "props": {
              "pageProps": {
                "rules": [
                  {
                    "shortName": "Second rule",
                    "description": "No spam",
                    "kind": "all",
                    "violationReason": "Spam",
                    "priority": 1
                  },
                  {
                    "shortName": "First rule",
                    "description": "Be kind",
                    "kind": "comment",
                    "violationReason": "Unkind",
                    "priority": 0
                  }
                ]
              }
            }
          }
        '''),
        200,
      ),
    );

    final rules = await repository.fetchRules('flutter');

    expect(rules, hasLength(2));
    expect(rules[0].shortName, 'Second rule');
    expect(rules[0].description, 'No spam');
    expect(rules[0].kind, 'all');
    expect(rules[0].violationReason, 'Spam');
    expect(rules[0].priority, 1);
    expect(rules[1].shortName, 'First rule');

    verify(
      () => mockHttp.get(
        Uri.parse('https://www.reddit.com/r/flutter/about/rules'),
        headers: any(named: 'headers'),
      ),
    ).called(1);
  });
}
