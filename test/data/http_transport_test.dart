import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/api_types.dart';
import 'package:fspez/src/data/http_transport.dart';
import 'package:fspez/src/domain/models/session_cookie.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class _MockHttpClient extends Mock implements http.Client {}

void main() {
  late _MockHttpClient mockHttp;
  late HttpTransport transport;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    mockHttp = _MockHttpClient();
    transport = HttpTransport(httpClient: mockHttp);
  });

  group('getHtml', () {
    test('uses rawCookie when it contains reddit_session', () async {
      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response('<html></html>', 200));

      final cookie = SessionCookie(
        value: 'abc123',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
        rawCookie: 'reddit_session=abc123; loid=xyz',
      );

      await transport.getHtml(
        Uri.parse('https://www.reddit.com/'),
        cookie,
      );

      verify(() => mockHttp.get(
            any(),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
              'Accept':
                  'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
              'Cookie': 'reddit_session=abc123; loid=xyz',
            },
          )).called(1);
    });

    test('falls back to value when rawCookie is null', () async {
      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response('<html></html>', 200));

      final cookie = SessionCookie(
        value: 'abc123',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );

      await transport.getHtml(
        Uri.parse('https://www.reddit.com/'),
        cookie,
      );

      verify(() => mockHttp.get(
            any(),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
              'Accept':
                  'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
              'Cookie': 'reddit_session=abc123',
            },
          )).called(1);
    });

    test('includes reddit_session when rawCookie lacks it', () async {
      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response('<html></html>', 200));

      final cookie = SessionCookie(
        value: 'abc123',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
        rawCookie: 'loid=xyz; session_tracker=def',
      );

      await transport.getHtml(
        Uri.parse('https://www.reddit.com/'),
        cookie,
      );

      verify(() => mockHttp.get(
            any(),
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

  group('getXml', () {
    test('uses rawCookie when it contains reddit_session', () async {
      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response('<feed></feed>', 200));

      final cookie = SessionCookie(
        value: 'abc123',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
        rawCookie: 'reddit_session=abc123; loid=xyz',
      );

      await transport.getXml(
        Uri.parse('https://www.reddit.com/.rss'),
        cookie,
      );

      verify(() => mockHttp.get(
            any(),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
              'Accept':
                  'application/xml,application/atom+xml,text/xml;q=0.9,*/*;q=0.8',
              'Cookie': 'reddit_session=abc123; loid=xyz',
            },
          )).called(1);
    });

    test('includes reddit_session when rawCookie lacks it', () async {
      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response('<feed></feed>', 200));

      final cookie = SessionCookie(
        value: 'abc123',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
        rawCookie: 'loid=xyz; session_tracker=def',
      );

      await transport.getXml(
        Uri.parse('https://www.reddit.com/.rss'),
        cookie,
      );

      verify(() => mockHttp.get(
            any(),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
              'Accept':
                  'application/xml,application/atom+xml,text/xml;q=0.9,*/*;q=0.8',
              'Cookie': 'reddit_session=abc123',
            },
          )).called(1);
    });
  });

  group('postForm with oldReddit endpoint', () {
    test('includes reddit_session when rawCookie lacks it', () async {
      when(() => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('{}', 200));

      final cookie = SessionCookie(
        value: 'abc123',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
        rawCookie: 'loid=xyz; session_tracker=def',
        modhash: 'mod123',
      );

      await transport.postForm(
        '/api/del',
        {'id': 't3_abc'},
        cookie,
        endpoint: ApiEndpoint.oldReddit,
        useOldReddit: true,
      );

      verify(() => mockHttp.post(
            any(),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
              'Content-Type':
                  'application/x-www-form-urlencoded; charset=UTF-8',
              'Cookie': 'reddit_session=abc123',
              'Accept': '*/*',
              'X-Requested-With': 'XMLHttpRequest',
              'X-Modhash': 'mod123',
            },
            body: any(named: 'body'),
          )).called(1);
    });
  });
}
