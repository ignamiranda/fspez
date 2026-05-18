import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/vote_notifier.dart';
import 'package:fspez/src/data/vote_repository.dart';
import 'package:fspez/src/domain/enums/vote_direction.dart';
import 'package:mocktail/mocktail.dart';

class _MockVoteRepository extends Mock implements VoteRepository {}

void main() {
  late _MockVoteRepository mockRepo;
  late VoteNotifier notifier;

  setUp(() {
    mockRepo = _MockVoteRepository();
    when(() => mockRepo.vote(any(), any(), sessionCookie: any(named: 'sessionCookie')))
        .thenAnswer((_) async {});
    notifier = VoteNotifier(mockRepo, null);
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

    test('calls repository with correct parameters', () async {
      await notifier.vote('t3_post1', VoteDirection.upvote);

      verify(() => mockRepo.vote('t3_post1', 1, sessionCookie: null)).called(1);
    });

    test('calls repository with downvote direction', () async {
      await notifier.vote('t3_post1', VoteDirection.downvote);

      verify(() => mockRepo.vote('t3_post1', -1, sessionCookie: null)).called(1);
    });

    test('keeps optimistic state even if repository throws', () async {
      when(() => mockRepo.vote(any(), any(), sessionCookie: any(named: 'sessionCookie')))
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
