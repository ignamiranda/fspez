import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/username_extractor.dart';
import 'package:fspez/src/data/reddit_client.dart';
import 'package:fspez/src/domain/models/session_cookie.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class _MockHttpClient extends Mock implements http.Client {}

void main() {
  late _MockHttpClient mockHttp;
  late UsernameExtractor extractor;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    mockHttp = _MockHttpClient();
    extractor = UsernameExtractor(redditClient: RedditClient(httpClient: mockHttp));
  });

  final cookie = SessionCookie(
    value: 'abc123',
    expiresAt: DateTime.now().add(const Duration(days: 1)),
  );

  group('API call strategy', () {
    test('returns username from /api/me when name is present', () async {
      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(
            '{"data": {"name": "testuser", "modhash": "abc"}}', 200));

      final username = await extractor.extract(cookie);

      expect(username, 'testuser');
    });

    test('falls through to cookie heuristic when API fails', () async {
      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response('Not Found', 404));

      final username = await extractor.extract(cookie);

      expect(username, isNotEmpty);
      expect(username, isNot(contains(' ')));
    });
  });

  group('Cookie heuristic strategy', () {
    test('extracts username-like string from raw cookie value', () async {
      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response('Not Found', 404));

      final username = await extractor.extract(cookie);

      expect(username, isNotEmpty);
      expect(username.length, lessThan(30));
    });
  });
}
