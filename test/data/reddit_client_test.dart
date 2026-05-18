import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/reddit_client.dart';
import 'package:fspez/src/domain/models/session_cookie.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class _MockHttpClient extends Mock implements http.Client {}

void main() {
  late _MockHttpClient mockHttp;
  late RedditClient client;

  setUp(() {
    mockHttp = _MockHttpClient();
    client = RedditClient(httpClient: mockHttp);
  });

  group('get', () {
    test('sends request without cookie when no session provided', () async {
      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response('{}', 200));

      await client.get('/best');

      verify(() => mockHttp.get(
            Uri.parse('https://www.reddit.com/best.json'),
            headers: {
              'User-Agent': 'fspez/0.1.0',
              'Content-Type': 'application/json',
            },
          )).called(1);
    });

    test('sends request with cookie when session provided', () async {
      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response('{}', 200));

      final cookie = SessionCookie(
        value: 'abc123',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );

      await client.get('/best', sessionCookie: cookie);

      verify(() => mockHttp.get(
            Uri.parse('https://www.reddit.com/best.json'),
            headers: {
              'User-Agent': 'fspez/0.1.0',
              'Content-Type': 'application/json',
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
        () => client.get('/best'),
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
          )).thenAnswer((_) async => http.Response('{}', 200));

      await client.get('/r/all',
          queryParams: {'sort': 'hot', 'limit': '25'});

      verify(() => mockHttp.get(
            Uri.parse(
                'https://www.reddit.com/r/all.json?sort=hot&limit=25'),
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
          body: {'action': 'sub', 'sr_name': 'flutter'},
          sessionCookie: cookie);

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
}
