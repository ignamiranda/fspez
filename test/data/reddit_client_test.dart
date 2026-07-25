import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/reddit_client.dart';
import 'package:fspez/src/domain/models/session_cookie.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class _MockHttpClient extends Mock implements http.Client {}

void main() {
  late _MockHttpClient mockHttp;
  late RedditClient client;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    mockHttp = _MockHttpClient();
    client = RedditClient(httpClient: mockHttp);
  });

  group('getRss', () {
    test('sends request and returns XML body on success', () async {
      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response('<feed></feed>', 200));

      final result = await client.getRss('/r/flutter');

      expect(result, '<feed></feed>');
      verify(() => mockHttp.get(
            Uri.parse('https://www.reddit.com/r/flutter.rss'),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
              'Accept':
                  'application/xml,application/atom+xml,text/xml;q=0.9,*/*;q=0.8',
              'Cookie': 'reddit_session=',
            },
          )).called(1);
    });

    test('passes cookie in RSS request', () async {
      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response('<feed></feed>', 200));

      final cookie = SessionCookie(
        value: 'abc123',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );

      await client.getRss('/r/flutter', sessionCookie: cookie);

      verify(() => mockHttp.get(
            Uri.parse('https://www.reddit.com/r/flutter.rss'),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
              'Accept':
                  'application/xml,application/atom+xml,text/xml;q=0.9,*/*;q=0.8',
              'Cookie': 'reddit_session=abc123',
            },
          )).called(1);
    });

    test('throws RedditApiException on error status', () async {
      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response('Not Found', 404));

      expect(
        () => client.getRss('/best'),
        throwsA(isA<RedditApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          404,
        )),
      );
    });

    test('passes query parameters', () async {
      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response('<feed></feed>', 200));

      await client
          .getRss('/r/all', queryParams: {'sort': 'hot', 'limit': '25'});

      verify(() => mockHttp.get(
            Uri.parse('https://www.reddit.com/r/all.rss?sort=hot&limit=25'),
            headers: any(named: 'headers'),
          )).called(1);
    });
  });

  group('post', () {
    test('sends POST with cookie when session provided', () async {
      when(() => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('{}', 200));

      final cookie = SessionCookie(
        value: 'abc123',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );

      await client.post('/api/subscribe',
          body: {'action': 'sub', 'sr_name': 'flutter'}, sessionCookie: cookie);

      verify(() => mockHttp.post(
            Uri.parse('https://www.reddit.com/api/subscribe'),
            headers: {
              'User-Agent': 'fspez/0.1.0',
              'Content-Type': 'application/json',
              'Cookie': 'reddit_session=abc123',
            },
            body: any(named: 'body'),
          )).called(1);
    });
  });

  group('getHtml', () {
    test('sends browser headers and cookie', () async {
      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response('<html></html>', 200));

      final cookie = SessionCookie(
        value: 'abc123',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );

      await client.getHtml(
        '/r/flutter/comments/post1',
        queryParams: {'sort': 'new'},
        sessionCookie: cookie,
      );

      verify(() => mockHttp.get(
            Uri.parse(
                'https://www.reddit.com/r/flutter/comments/post1?sort=new'),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
              'Accept':
                  'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
              'Cookie': 'reddit_session=abc123',
            },
          )).called(1);
    });
  });
}
