import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/feed_repository.dart';
import 'package:fspez/src/data/reddit_client.dart';
import 'package:fspez/src/domain/models/session_cookie.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class _MockHttpClient extends Mock implements http.Client {}

void main() {
  late _MockHttpClient mockHttp;
  late RedditClient client;
  late FeedRepository repository;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    mockHttp = _MockHttpClient();
    client = RedditClient(httpClient: mockHttp);
    repository = FeedRepository(client);
  });

  void stubFeedResponses(String jsonBody, {String htmlBody = '<html></html>'}) {
    when(() => mockHttp.get(
          any(),
          headers: any(named: 'headers'),
        )).thenAnswer((invocation) async {
      final uri = invocation.positionalArguments[0] as Uri;
      if (uri.path.endsWith('.json')) {
        return http.Response(jsonBody, 200);
      }
      return http.Response(htmlBody, 200,
          headers: {'content-type': 'text/html'});
    });
  }

  group('fetchSaved', () {
    test('GETs user saved endpoint and returns feed', () async {
      stubFeedResponses('''
        {
          "data": {
            "children": [
              {
                "kind": "t3",
                "data": {
                  "id": "saved1",
                  "title": "Saved Post 1",
                  "permalink": "/r/test/1",
                  "created_utc": 1000000000
                }
              },
              {
                "kind": "t3",
                "data": {
                  "id": "saved2",
                  "title": "Saved Post 2",
                  "permalink": "/r/test/2",
                  "created_utc": 1000000000
                }
              }
            ],
            "after": "t3_cursor",
            "before": null
          }
        }
      ''');

      final feed = await repository.fetchSaved('testuser');

      expect(feed.posts.length, 2);
      expect(feed.posts[0].id, 'saved1');
      expect(feed.posts[1].id, 'saved2');
      expect(feed.after, 't3_cursor');
      expect(feed.hasMorePages, true);

      verify(() => mockHttp.get(
            Uri.parse('https://old.reddit.com/user/testuser/saved.json'
                '?limit=25&sr_detail=true'),
            headers: any(named: 'headers'),
          )).called(1);
    });

    test('passes after cursor', () async {
      stubFeedResponses('''
        {"data": {"children": [], "after": null, "before": null}}
      ''');

      await repository.fetchSaved('testuser', after: 't3_cursor');

      verify(() => mockHttp.get(
            Uri.parse('https://old.reddit.com/user/testuser/saved.json'
                '?after=t3_cursor&limit=25&sr_detail=true'),
            headers: any(named: 'headers'),
          )).called(1);
    });

    test('sends cookie when session provided', () async {
      stubFeedResponses('''
        {"data": {"children": [], "after": null, "before": null}}
      ''');

      final cookie = SessionCookie(
        value: 'session_val',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );

      await repository.fetchSaved('testuser', sessionCookie: cookie);

      verify(() => mockHttp.get(
            any(),
            headers: {
              'User-Agent': 'fspez/0.1.0',
              'Content-Type': 'application/json',
              'Cookie': 'reddit_session=session_val',
            },
          )).called(1);
    });

    test('throws RedditApiException on error', () async {
      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response('Not Found', 404));

      expect(
        () => repository.fetchSaved('testuser'),
        throwsA(isA<RedditApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          404,
        )),
      );
    });

    test('returns saved FeedKind', () async {
      stubFeedResponses('''
        {"data": {"children": [], "after": null, "before": null}}
      ''');

      final feed = await repository.fetchSaved('testuser');

      expect(feed.kind.name, 'saved');
    });

    test('overlays award counts from html feed markup', () async {
      stubFeedResponses(
        '''
        {
          "data": {
            "children": [
              {
                "kind": "t3",
                "data": {
                  "id": "saved1",
                  "title": "Saved Post 1",
                  "permalink": "/r/test/1",
                  "created_utc": 1000000000
                }
              }
            ],
            "after": null,
            "before": null
          }
        }
      ''',
        htmlBody:
            '<shreddit-post id="t3_saved1" award-count="4"></shreddit-post>',
      );

      final feed = await repository.fetchSaved('testuser');

      expect(feed.posts.single.awardCount, 4);
    });
  });
}
