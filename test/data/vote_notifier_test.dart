import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/vote_notifier.dart';
import 'package:fspez/src/data/reddit_client.dart';
import 'package:fspez/src/domain/enums/vote_direction.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;

class _MockHttpClient extends Mock implements http.Client {}

void main() {
  late _MockHttpClient mockHttp;
  late RedditClient client;
  late VoteNotifier notifier;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    mockHttp = _MockHttpClient();
    when(() => mockHttp.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
        .thenAnswer((_) async => http.Response('{}', 200));
    client = RedditClient(httpClient: mockHttp);
    notifier = VoteNotifier(client, null);
  });

  group('vote', () {
    test('stores optimistic vote direction', () async {
      await notifier.vote('t3_post1', VoteDirection.upvote);
      expect(notifier.state['t3_post1'], VoteDirection.upvote);
    });

    test('updates existing vote', () async {
      await notifier.vote('t3_post1', VoteDirection.upvote);
      await notifier.vote('t3_post1', VoteDirection.downvote);
      expect(notifier.state['t3_post1'], VoteDirection.downvote);
    });

    test('calls api/vote with correct parameters', () async {
      await notifier.vote('t3_post1', VoteDirection.upvote);

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
      await notifier.vote('t3_post1', VoteDirection.downvote);

      verify(() => mockHttp.post(
        Uri.parse('https://www.reddit.com/api/vote'),
        headers: {
          'User-Agent': 'fspez/0.1.0',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'id=t3_post1&dir=-1',
      )).called(1);
    });

    test('keeps optimistic state even if api throws', () async {
      when(() => mockHttp.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenThrow(Exception('API error'));

      await notifier.vote('t3_post1', VoteDirection.upvote);

      expect(notifier.state['t3_post1'], VoteDirection.upvote);
    });
  });

  group('toggle', () {
    test('toggles from none to upvote', () {
      notifier.toggle('t3_p1', VoteDirection.upvote);
      expect(notifier.state['t3_p1'], VoteDirection.upvote);
    });

    test('toggles from upvote back to none', () async {
      await notifier.vote('t3_p1', VoteDirection.upvote);
      notifier.toggle('t3_p1', VoteDirection.upvote);
      expect(notifier.state['t3_p1'], VoteDirection.none);
    });

    test('toggles from downvote to upvote', () async {
      await notifier.vote('t3_p1', VoteDirection.downvote);
      notifier.toggle('t3_p1', VoteDirection.upvote);
      expect(notifier.state['t3_p1'], VoteDirection.upvote);
    });

    test('toggles from upvote to downvote', () async {
      await notifier.vote('t3_p1', VoteDirection.upvote);
      notifier.toggle('t3_p1', VoteDirection.downvote);
      expect(notifier.state['t3_p1'], VoteDirection.downvote);
    });

    test('maintains separate state for different fullnames', () async {
      await notifier.vote('t3_p1', VoteDirection.upvote);
      notifier.toggle('t3_p2', VoteDirection.upvote);

      expect(notifier.state['t3_p1'], VoteDirection.upvote);
      expect(notifier.state['t3_p2'], VoteDirection.upvote);
    });
  });

  group('effectiveVote', () {
    test('returns override when present', () async {
      await notifier.vote('t3_p1', VoteDirection.upvote);
      expect(
        notifier.effectiveVote('t3_p1', VoteDirection.none),
        VoteDirection.upvote,
      );
    });

    test('returns original when no override', () {
      expect(
        notifier.effectiveVote('t3_unknown', VoteDirection.downvote),
        VoteDirection.downvote,
      );
    });

    test('returns original after toggle off', () async {
      await notifier.vote('t3_p1', VoteDirection.upvote);
      notifier.toggle('t3_p1', VoteDirection.upvote);

      expect(
        notifier.effectiveVote('t3_p1', VoteDirection.none),
        VoteDirection.none,
      );
    });
  });
}
