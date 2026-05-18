import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/vote_repository.dart';
import 'package:fspez/src/data/reddit_client.dart';
import 'package:fspez/src/domain/models/session_cookie.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class _MockHttpClient extends Mock implements http.Client {}

void main() {
  late _MockHttpClient mockHttp;
  late RedditClient client;
  late VoteRepository repository;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    mockHttp = _MockHttpClient();
    client = RedditClient(httpClient: mockHttp);
    repository = VoteRepository(client);
  });

  group('vote', () {
    test('sends POST with form-encoded body', () async {
      when(() => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('{}', 200));

      await repository.vote('t3_abc123', 1);

      verify(() => mockHttp.post(
            Uri.parse('https://www.reddit.com/api/vote'),
            headers: {
              'User-Agent': 'fspez/0.1.0',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: 'id=t3_abc123&dir=1',
          )).called(1);
    });

    test('sends dir=1 for upvote', () async {
      when(() => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('{}', 200));

      await repository.vote('t3_abc', 1);

      verify(() => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: 'id=t3_abc&dir=1',
          )).called(1);
    });

    test('sends dir=-1 for downvote', () async {
      when(() => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('{}', 200));

      await repository.vote('t3_abc', -1);

      verify(() => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: 'id=t3_abc&dir=-1',
          )).called(1);
    });

    test('sends dir=0 for clearing vote', () async {
      when(() => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('{}', 200));

      await repository.vote('t3_abc', 0);

      verify(() => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: 'id=t3_abc&dir=0',
          )).called(1);
    });

    test('sends cookie when session provided', () async {
      when(() => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('{}', 200));

      final cookie = SessionCookie(
        value: 'session_val',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );

      await repository.vote('t3_abc', 1, sessionCookie: cookie);

      verify(() => mockHttp.post(
            any(),
            headers: {
              'User-Agent': 'fspez/0.1.0',
              'Content-Type': 'application/x-www-form-urlencoded',
              'Cookie': 'reddit_session=session_val',
            },
            body: any(named: 'body'),
          )).called(1);
    });

    test('throws RedditApiException on error', () async {
      when(() => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('Forbidden', 403));

      expect(
        () => repository.vote('t3_abc', 1),
        throwsA(isA<RedditApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          403,
        )),
      );
    });
  });
}
