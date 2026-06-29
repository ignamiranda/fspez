import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/post_actions_notifier.dart';
import 'package:fspez/src/data/reddit_client.dart';
import 'package:fspez/src/domain/enums/vote_direction.dart';
import 'package:fspez/src/domain/models/session_cookie.dart';
import 'package:fspez/src/presentation/utils/interaction_helpers.dart';
import 'package:mocktail/mocktail.dart';

class _MockRedditClient extends Mock implements RedditClient {}

Widget _app(Widget body) => MaterialApp(home: Scaffold(body: body));

void main() {
  late _MockRedditClient mockClient;
  late PostActionsNotifier actions;

  setUpAll(() {
    registerFallbackValue(SessionCookie(value: '', expiresAt: DateTime.now()));
  });

  setUp(() {
    mockClient = _MockRedditClient();
    when(() => mockClient.postForm(any(),
            fields: any(named: 'fields'),
            sessionCookie: any(named: 'sessionCookie')))
        .thenAnswer((_) async => {});
    when(() => mockClient.save(any(), any())).thenAnswer((_) async {});
    when(() => mockClient.unsave(any(), any())).thenAnswer((_) async {});
    when(() => mockClient.hide(any(), any())).thenAnswer((_) async {});
    when(() => mockClient.unhide(any(), any())).thenAnswer((_) async {});
    final cookie = SessionCookie(
        value: 'abc', expiresAt: DateTime.now().add(const Duration(days: 1)));
    actions = PostActionsNotifier(mockClient, cookie);
  });

  group('handleVote', () {
    testWidgets('sets vote direction', (tester) async {
      handleVote(actions, 't3_test', VoteDirection.upvote);
      expect(actions.effectiveVote('t3_test', VoteDirection.none),
          VoteDirection.upvote);
    });

    testWidgets('overrides existing vote', (tester) async {
      await actions.vote('t3_test', VoteDirection.upvote);
      handleVote(actions, 't3_test', VoteDirection.downvote);
      expect(actions.effectiveVote('t3_test', VoteDirection.upvote),
          VoteDirection.downvote);
    });
  });

  group('handleSave', () {
    testWidgets('toggles from unsaved to saved', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(_app(Builder(builder: (c) {
        ctx = c;
        return const SizedBox.shrink();
      })));

      await handleSave(actions, 't3_test', ctx);

      expect(actions.effectiveSaved('t3_test', false), true);
    });

    testWidgets('toggles from saved to unsaved', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(_app(Builder(builder: (c) {
        ctx = c;
        return const SizedBox.shrink();
      })));

      await handleSave(actions, 't3_test', ctx);
      await handleSave(actions, 't3_test', ctx);

      expect(actions.effectiveSaved('t3_test', false), false);
    });

    testWidgets('reverts state on save failure', (tester) async {
      when(() => mockClient.save(any(), any())).thenThrow(
          const RedditApiException(statusCode: 403, message: 'Forbidden'));

      late BuildContext ctx;
      await tester.pumpWidget(_app(Builder(builder: (c) {
        ctx = c;
        return const SizedBox.shrink();
      })));

      await handleSave(actions, 't3_test', ctx);

      expect(actions.effectiveSaved('t3_test', false), false);
    });

    testWidgets('does not propagate save failure to caller', (tester) async {
      when(() => mockClient.save(any(), any())).thenThrow(
          const RedditApiException(statusCode: 403, message: 'Forbidden'));

      late BuildContext ctx;
      await tester.pumpWidget(_app(Builder(builder: (c) {
        ctx = c;
        return const SizedBox.shrink();
      })));

      expect(handleSave(actions, 't3_test', ctx), completes);
    });

    testWidgets('undo restores saved state after save', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(_app(Builder(builder: (c) {
        ctx = c;
        return const SizedBox.shrink();
      })));

      // Start unsaved, save it — snackbar shows "Saved".
      await handleSave(actions, 't3_test', ctx, wasSaved: false);
      await tester.pump();
      expect(actions.effectiveSaved('t3_test', false), true);
      expect(find.text('Saved'), findsOneWidget);

      // Simulate the snackbar Undo action (calls toggleSave directly).
      await actions.toggleSave('t3_test');
      expect(actions.effectiveSaved('t3_test', false), false);
    });

    testWidgets('undo restores saved state after unsave', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(_app(Builder(builder: (c) {
        ctx = c;
        return const SizedBox.shrink();
      })));

      // Start unsaved, save it first.
      await handleSave(actions, 't3_test', ctx, wasSaved: false);
      await tester.pump();
      expect(actions.effectiveSaved('t3_test', false), true);

      // Now unsave it — snackbar shows "Removed from saved".
      await handleSave(actions, 't3_test', ctx, wasSaved: true);
      await tester.pump();
      expect(actions.effectiveSaved('t3_test', false), false);
      expect(find.text('Removed from saved'), findsOneWidget);

      // Simulate the snackbar Undo action.
      await actions.toggleSave('t3_test');
      expect(actions.effectiveSaved('t3_test', false), true);
    });
  });

  group('handleUnhide', () {
    testWidgets('shows undo snackbar and re-hides on undo', (tester) async {
      late BuildContext ctx;
      var undoCalled = false;
      await actions.hide('t3_test');
      await tester.pumpWidget(_app(Builder(builder: (c) {
        ctx = c;
        return const SizedBox.shrink();
      })));

      await handleUnhide(actions, 't3_test', ctx, onUndo: () async {
        undoCalled = true;
      });
      await tester.pumpAndSettle();

      expect(find.text('Post unhidden'), findsOneWidget);
      expect(actions.state.hides.containsKey('t3_test'), isFalse);

      await tester.tap(find.text('Undo'), warnIfMissed: false);
      await tester.pump();

      expect(undoCalled, isTrue);
      expect(actions.state.hides['t3_test'], isTrue);
    });
  });
}
