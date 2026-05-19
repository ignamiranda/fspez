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

  group('save', () {
    test('sends POST to old.reddit.com with browser headers and modhash', () async {
      when(() => mockHttp.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response('{}', 200, headers: {'content-type': 'application/json'}));

      final cookie = SessionCookie(
        value: 'session_val',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
        rawCookie: 'reddit_session=session_val; loggedin=1',
        modhash: 'abc123modhash',
      );

      await client.save('t3_post1', cookie);

      verify(() => mockHttp.post(
        Uri.parse('https://old.reddit.com/api/save'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
          'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
          'Accept': '*/*',
          'X-Requested-With': 'XMLHttpRequest',
          'Cookie': 'reddit_session=session_val; loggedin=1',
          'X-Modhash': 'abc123modhash',
        },
        body: 'id=t3_post1',
      )).called(1);
    });

    test('sends without modhash when null', () async {
      when(() => mockHttp.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response('{}', 200, headers: {'content-type': 'application/json'}));

      final cookie = SessionCookie(
        value: 'session_val',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );

      await client.save('t3_post1', cookie);

      verify(() => mockHttp.post(
        any(),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
          'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
          'Accept': '*/*',
          'X-Requested-With': 'XMLHttpRequest',
          'Cookie': 'reddit_session=session_val',
        },
        body: 'id=t3_post1',
      )).called(1);
    });

    test('throws RedditApiException on error', () async {
      when(() => mockHttp.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response('Forbidden', 403, headers: {'content-type': 'text/html'}));

      final cookie = SessionCookie(
        value: 'val',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );

      expect(
        () => client.save('t3_1', cookie),
        throwsA(isA<RedditApiException>().having((e) => e.statusCode, 'statusCode', 403)),
      );
    });
  });

  group('unsave', () {
    test('sends POST to old.reddit.com/api/unsave', () async {
      when(() => mockHttp.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response('{}', 200, headers: {'content-type': 'application/json'}));

      final cookie = SessionCookie(
        value: 'val',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );

      await client.unsave('t3_post1', cookie);

      verify(() => mockHttp.post(
        Uri.parse('https://old.reddit.com/api/unsave'),
        headers: any(named: 'headers'),
        body: 'id=t3_post1',
      )).called(1);
    });
  });
}
