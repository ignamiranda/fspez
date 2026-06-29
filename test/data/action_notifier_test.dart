import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/action_notifier.dart';
import 'package:fspez/src/data/reddit_client.dart';
import 'package:fspez/src/data/write_operation_notifier.dart';
import 'package:fspez/src/domain/enums/vote_direction.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;

class _MockHttpClient extends Mock implements http.Client {}

void main() {
  late _MockHttpClient mockHttp;
  late RedditClient client;
  late ActionNotifier<VoteDirection> notifier;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    mockHttp = _MockHttpClient();
    when(() => mockHttp.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
        .thenAnswer((_) async => http.Response('{}', 200));
    client = RedditClient(httpClient: mockHttp);
    notifier = ActionNotifier<VoteDirection>(client, null);
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
        () => notifier.redditClient.postForm('/api/vote',
            fields: {'id': 't3_post1', 'dir': '1'},
            sessionCookie: null));

      verify(() => mockHttp.post(
        Uri.parse('https://www.reddit.com/api/vote'),
        headers: {
          'User-Agent': 'fspez/0.1.0',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'id=t3_post1&dir=1',
      )).called(1);
    });

    test('calls api/vote with downvote direction', () async {
      await notifier.write('t3_post1', VoteDirection.downvote, null,
        () => notifier.redditClient.postForm('/api/vote',
            fields: {'id': 't3_post1', 'dir': '-1'},
            sessionCookie: null));

      verify(() => mockHttp.post(
        Uri.parse('https://www.reddit.com/api/vote'),
        headers: {
          'User-Agent': 'fspez/0.1.0',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'id=t3_post1&dir=-1',
      )).called(1);
    });

    test('keeps optimistic state even if api throws with keepOptimistic', () async {
      when(() => mockHttp.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenThrow(Exception('API error'));

      await expectLater(
        notifier.write('t3_post1', VoteDirection.upvote, null,
          () => notifier.redditClient.postForm('/api/vote',
              fields: {'id': 't3_post1', 'dir': '1'},
              sessionCookie: null),
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
