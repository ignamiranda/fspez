import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/session_info.dart';
import 'package:fspez/src/data/reddit_client.dart';
import 'package:fspez/src/domain/models/session_cookie.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class _MockHttpClient extends Mock implements http.Client {}

void main() {
  late _MockHttpClient mockHttp;
  late RedditClient redditClient;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    mockHttp = _MockHttpClient();
    redditClient = RedditClient(httpClient: mockHttp);
  });

  final cookie = SessionCookie(
    value: 'abc123',
    expiresAt: DateTime.now().add(const Duration(days: 1)),
  );

  group('fetchSessionInfo', () {
    test('returns username and modhash from /api/me', () async {
      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(
            '{"data": {"modhash": "abc123modhash", "name": "testuser"}}', 200));

      final info = await fetchSessionInfo(redditClient, cookie);

      expect(info.username, 'testuser');
      expect(info.modhash, 'abc123modhash');
      verify(() => mockHttp.get(
            Uri.parse('https://old.reddit.com/api/me.json'),
            headers: any(named: 'headers'),
          )).called(1);
    });

    test('returns username with null modhash when modhash field is missing',
        () async {
      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(
            '{"data": {"name": "testuser"}}', 200));

      final info = await fetchSessionInfo(redditClient, cookie);

      expect(info.username, 'testuser');
      expect(info.modhash, isNull);
    });

    test('returns defaults on API error', () async {
      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response('Not Found', 404));

      final info = await fetchSessionInfo(redditClient, cookie);

      expect(info.username, 'unknown');
      expect(info.modhash, isNull);
    });

    test('returns username with null modhash on empty modhash string',
        () async {
      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(
            '{"data": {"modhash": "", "name": "testuser"}}', 200));

      final info = await fetchSessionInfo(redditClient, cookie);

      expect(info.username, 'testuser');
      expect(info.modhash, isNull);
    });
  });
}