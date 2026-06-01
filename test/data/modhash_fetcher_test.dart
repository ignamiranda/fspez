import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/modhash_fetcher.dart';
import 'package:fspez/src/data/reddit_client.dart';
import 'package:fspez/src/domain/models/session_cookie.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class _MockHttpClient extends Mock implements http.Client {}

void main() {
  late _MockHttpClient mockHttp;
  late ModhashFetcher fetcher;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    mockHttp = _MockHttpClient();
    fetcher = ModhashFetcher(redditClient: RedditClient(httpClient: mockHttp));
  });

  final cookie = SessionCookie(
    value: 'abc123',
    expiresAt: DateTime.now().add(const Duration(days: 1)),
  );

  test('fetch returns modhash from /api/me response', () async {
    when(() => mockHttp.get(
          any(),
          headers: any(named: 'headers'),
        )).thenAnswer((_) async => http.Response(
          '{"data": {"modhash": "abc123modhash", "name": "testuser"}}', 200));

    final modhash = await fetcher.fetch(cookie);

    expect(modhash, 'abc123modhash');
    verify(() => mockHttp.get(
          Uri.parse('https://old.reddit.com/api/me.json'),
          headers: any(named: 'headers'),
        )).called(1);
  });

  test('fetch returns null when modhash field is missing', () async {
    when(() => mockHttp.get(
          any(),
          headers: any(named: 'headers'),
        )).thenAnswer((_) async => http.Response(
          '{"data": {"name": "testuser"}}', 200));

    final modhash = await fetcher.fetch(cookie);

    expect(modhash, isNull);
  });

  test('fetch returns null on API error', () async {
    when(() => mockHttp.get(
          any(),
          headers: any(named: 'headers'),
        )).thenAnswer((_) async => http.Response('Not Found', 404));

    final modhash = await fetcher.fetch(cookie);

    expect(modhash, isNull);
  });

  test('fetch returns null on empty modhash string', () async {
    when(() => mockHttp.get(
          any(),
          headers: any(named: 'headers'),
        )).thenAnswer((_) async => http.Response(
          '{"data": {"modhash": ""}}', 200));

    final modhash = await fetcher.fetch(cookie);

    expect(modhash, isNull);
  });
}
