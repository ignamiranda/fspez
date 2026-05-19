import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/reddit_client.dart';
import 'package:fspez/src/data/save_repository.dart';
import 'package:fspez/src/domain/models/session_cookie.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class _MockHttpClient extends Mock implements http.Client {}

void main() {
  late _MockHttpClient mockHttp;
  late RedditClient redditClient;
  late SaveRepository repository;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    mockHttp = _MockHttpClient();
    redditClient = RedditClient(httpClient: mockHttp);
    repository = SaveRepository(redditClient);
  });

  group('save', () {
    test('throws SaveException when no session', () {
      expect(
        () => repository.save('t3_abc'),
        throwsA(isA<SaveException>().having((e) => e.statusCode, 'statusCode', 0)),
      );
    });

    test('calls client.save with session cookie', () async {
      when(() => mockHttp.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response('{}', 200, headers: {'content-type': 'application/json'}));

      final cookie = SessionCookie(value: 'abc', expiresAt: DateTime.now().add(const Duration(days: 1)));
      await repository.save('t3_abc', sessionCookie: cookie);

      verify(() => mockHttp.post(
        Uri.parse('https://old.reddit.com/api/save'),
        headers: any(named: 'headers'),
        body: 'id=t3_abc',
      )).called(1);
    });
  });

  group('unsave', () {
    test('throws SaveException when no session', () {
      expect(
        () => repository.unsave('t3_abc'),
        throwsA(isA<SaveException>().having((e) => e.statusCode, 'statusCode', 0)),
      );
    });

    test('calls client.unsave with session cookie', () async {
      when(() => mockHttp.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response('{}', 200, headers: {'content-type': 'application/json'}));

      final cookie = SessionCookie(value: 'abc', expiresAt: DateTime.now().add(const Duration(days: 1)));
      await repository.unsave('t3_abc', sessionCookie: cookie);

      verify(() => mockHttp.post(
        Uri.parse('https://old.reddit.com/api/unsave'),
        headers: any(named: 'headers'),
        body: 'id=t3_abc',
      )).called(1);
    });
  });
}
