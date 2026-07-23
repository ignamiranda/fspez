import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/http_transport.dart';
import 'package:fspez/src/data/interaction_client.dart';
import 'package:fspez/src/data/write_operation_notifier.dart';
import 'package:fspez/src/domain/enums/vote_direction.dart';
import 'package:fspez/src/domain/models/session_cookie.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;

class _MockHttpClient extends Mock implements http.Client {}

SessionCookie _testCookie() {
  return SessionCookie(
    value: 'test',
    expiresAt: DateTime.now().add(const Duration(days: 1)),
  );
}

void main() {
  late _MockHttpClient mockHttp;
  late InteractionClient interactionClient;
  late WriteOperationNotifier<VoteDirection> notifier;
  late SessionCookie cookie;

  setUpAll(() {
    registerFallbackValue(Uri());
    registerFallbackValue(_testCookie());
  });

  setUp(() {
    mockHttp = _MockHttpClient();
    cookie = _testCookie();
    when(() => mockHttp.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
        .thenAnswer((_) async => http.Response('{}', 200));
    interactionClient = InteractionClient(HttpTransport(httpClient: mockHttp));
    notifier = WriteOperationNotifier<VoteDirection>(null);
  });

  group('write', () {
    test('stores optimistic value', () async {
      await notifier.write('t3_post1', VoteDirection.upvote, null,
        () => Future.value());
      expect(notifier.state['t3_post1'], VoteDirection.upvote);
    });

    test('updates existing value', () async {
      await notifier.write('t3_post1', VoteDirection.upvote, null,
        () => Future.value());
      await notifier.write('t3_post1', VoteDirection.downvote, VoteDirection.upvote,
        () => Future.value());
      expect(notifier.state['t3_post1'], VoteDirection.downvote);
    });

    test('calls api/vote with correct parameters', () async {
      await notifier.write('t3_post1', VoteDirection.upvote, null,
        () => interactionClient.vote(
          fullname: 't3_post1',
          direction: 1,
          sessionCookie: cookie,
        ));

      verify(() => mockHttp.post(
        Uri.parse('https://www.reddit.com/api/vote'),
        headers: {
          'User-Agent': 'fspez/0.1.0',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Cookie': 'reddit_session=test',
        },
        body: 'id=t3_post1&dir=1',
      )).called(1);
    });

    test('calls api/vote with downvote direction', () async {
      await notifier.write('t3_post1', VoteDirection.downvote, null,
        () => interactionClient.vote(
          fullname: 't3_post1',
          direction: -1,
          sessionCookie: cookie,
        ));

      verify(() => mockHttp.post(
        Uri.parse('https://www.reddit.com/api/vote'),
        headers: {
          'User-Agent': 'fspez/0.1.0',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Cookie': 'reddit_session=test',
        },
        body: 'id=t3_post1&dir=-1',
      )).called(1);
    });

    test('keeps optimistic state even if api throws with keepOptimistic', () async {
      when(() => mockHttp.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenThrow(Exception('API error'));

      await expectLater(
        notifier.write('t3_post1', VoteDirection.upvote, null,
          () => interactionClient.vote(
            fullname: 't3_post1',
            direction: 1,
            sessionCookie: cookie,
          ),
          onError: WriteErrorPolicy.keepOptimistic),
        throwsA(isA<Exception>()),
      );

      expect(notifier.state['t3_post1'], VoteDirection.upvote);
    });
  });

  group('effectiveValue', () {
    test('returns override when present', () async {
      await notifier.write('t3_p1', VoteDirection.upvote, null,
        () => Future.value());
      expect(
        notifier.effectiveValue('t3_p1', VoteDirection.none),
        VoteDirection.upvote,
      );
    });

    test('returns original when no override', () {
      expect(
        notifier.effectiveValue('t3_unknown', VoteDirection.downvote),
        VoteDirection.downvote,
      );
    });

    test('returns original after revert', () async {
      await notifier.write('t3_p1', VoteDirection.upvote, null,
        () => Future.value());
      await notifier.write('t3_p1', VoteDirection.none, VoteDirection.upvote,
        () => Future.value());
      expect(
        notifier.effectiveValue('t3_p1', VoteDirection.none),
        VoteDirection.none,
      );
    });
  });
}
