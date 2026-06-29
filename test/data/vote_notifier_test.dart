import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/interaction_client.dart';
import 'package:fspez/src/data/vote_notifier.dart';
import 'package:fspez/src/domain/enums/vote_direction.dart';
import 'package:fspez/src/domain/models/session_cookie.dart';
import 'package:mocktail/mocktail.dart';

class _MockInteractionClient extends Mock implements InteractionClient {}

SessionCookie _cookie() {
  return SessionCookie(
    value: 'abc',
    expiresAt: DateTime.now().add(const Duration(days: 1)),
  );
}

void main() {
  late _MockInteractionClient mockClient;
  late SessionCookie cookie;
  late VoteNotifier notifier;

  setUpAll(() {
    registerFallbackValue(_cookie());
  });

  setUp(() {
    mockClient = _MockInteractionClient();
    cookie = _cookie();
    when(() => mockClient.vote(
          fullname: any(named: 'fullname'),
          direction: any(named: 'direction'),
          sessionCookie: any(named: 'sessionCookie'),
        )).thenAnswer((_) async {});
    notifier = VoteNotifier(mockClient, cookie);
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

    test('calls vote with correct parameters', () async {
      await notifier.vote('t3_post1', VoteDirection.upvote);

      verify(() => mockClient.vote(
            fullname: 't3_post1',
            direction: 1,
            sessionCookie: cookie,
          )).called(1);
    });

    test('calls vote with downvote direction', () async {
      await notifier.vote('t3_post1', VoteDirection.downvote);

      verify(() => mockClient.vote(
            fullname: 't3_post1',
            direction: -1,
            sessionCookie: cookie,
          )).called(1);
    });

    test('keeps optimistic state even if api throws', () async {
      when(() => mockClient.vote(
            fullname: any(named: 'fullname'),
            direction: any(named: 'direction'),
            sessionCookie: any(named: 'sessionCookie'),
          )).thenThrow(Exception('API error'));

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
