import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/save_notifier.dart';
import 'package:fspez/src/data/save_repository.dart' show SaveRepository, SaveException;
import 'package:fspez/src/data/vote_notifier.dart';
import 'package:fspez/src/data/vote_repository.dart';
import 'package:fspez/src/domain/enums/vote_direction.dart';
import 'package:fspez/src/presentation/utils/interaction_helpers.dart';
import 'package:mocktail/mocktail.dart';

class _MockVoteRepository extends Mock implements VoteRepository {}
class _MockSaveRepository extends Mock implements SaveRepository {}

Widget _app(Widget body) => MaterialApp(home: Scaffold(body: body));

void main() {
  late _MockVoteRepository mockVoteRepo;
  late _MockSaveRepository mockSaveRepo;
  late VoteNotifier voteNotifier;
  late SaveNotifier saveNotifier;

  setUp(() {
    mockVoteRepo = _MockVoteRepository();
    mockSaveRepo = _MockSaveRepository();
    when(() => mockVoteRepo.vote(any(), any(), sessionCookie: any(named: 'sessionCookie')))
        .thenAnswer((_) async {});
    when(() => mockSaveRepo.save(any(), sessionCookie: any(named: 'sessionCookie')))
        .thenAnswer((_) async {});
    when(() => mockSaveRepo.unsave(any(), sessionCookie: any(named: 'sessionCookie')))
        .thenAnswer((_) async {});
    voteNotifier = VoteNotifier(mockVoteRepo, null);
    saveNotifier = SaveNotifier(mockSaveRepo, null);
  });

  group('handleVote', () {
    test('toggles vote on notifier', () {
      handleVote(voteNotifier, 't3_test', VoteDirection.upvote);
      expect(voteNotifier.effectiveVote('t3_test', VoteDirection.none),
          VoteDirection.upvote);
    });

    test('toggles from upvote to none', () async {
      await voteNotifier.vote('t3_test', VoteDirection.upvote);
      handleVote(voteNotifier, 't3_test', VoteDirection.upvote);
      expect(voteNotifier.effectiveVote('t3_test', VoteDirection.none),
          VoteDirection.none);
    });

    test('toggles from downvote to upvote', () async {
      await voteNotifier.vote('t3_test', VoteDirection.downvote);
      handleVote(voteNotifier, 't3_test', VoteDirection.upvote);
      expect(voteNotifier.effectiveVote('t3_test', VoteDirection.upvote),
          VoteDirection.upvote);
    });
  });

  group('handleSave', () {
    testWidgets('toggles from unsaved to saved', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(_app(Builder(builder: (c) {
        ctx = c;
        return const SizedBox.shrink();
      })));

      await handleSave(saveNotifier, 't3_test', ctx);

      expect(saveNotifier.effectiveSaved('t3_test', false), true);
    });

    testWidgets('toggles from saved to unsaved', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(_app(Builder(builder: (c) {
        ctx = c;
        return const SizedBox.shrink();
      })));

      await handleSave(saveNotifier, 't3_test', ctx);
      await handleSave(saveNotifier, 't3_test', ctx);

      expect(saveNotifier.effectiveSaved('t3_test', false), false);
    });

    testWidgets('reverts state on save failure', (tester) async {
      when(() => mockSaveRepo.save(any(), sessionCookie: any(named: 'sessionCookie')))
          .thenThrow(SaveException(statusCode: 403, body: 'Forbidden'));

      late BuildContext ctx;
      await tester.pumpWidget(_app(Builder(builder: (c) {
        ctx = c;
        return const SizedBox.shrink();
      })));

      await handleSave(saveNotifier, 't3_test', ctx);

      expect(saveNotifier.effectiveSaved('t3_test', false), false);
    });

    testWidgets('does not propagate save failure to caller', (tester) async {
      when(() => mockSaveRepo.save(any(), sessionCookie: any(named: 'sessionCookie')))
          .thenThrow(SaveException(statusCode: 403, body: 'Forbidden'));

      late BuildContext ctx;
      await tester.pumpWidget(_app(Builder(builder: (c) {
        ctx = c;
        return const SizedBox.shrink();
      })));

      expect(handleSave(saveNotifier, 't3_test', ctx), completes);
    });
  });
}
