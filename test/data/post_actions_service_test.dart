import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/post_actions_notifier.dart';
import 'package:fspez/src/data/reddit_client.dart';
import 'package:fspez/src/domain/enums/vote_direction.dart';
import 'package:fspez/src/domain/models/session_cookie.dart';
import 'package:mocktail/mocktail.dart';

class _MockRedditClient extends Mock implements RedditClient {}

SessionCookie _cookie() {
  return SessionCookie(
    value: 'abc',
    expiresAt: DateTime.now().add(const Duration(days: 1)),
  );
}

void main() {
  late _MockRedditClient client;
  late SessionCookie cookie;
  late PostActionsNotifier notifier;

  setUpAll(() {
    registerFallbackValue(_cookie());
  });

  setUp(() {
    client = _MockRedditClient();
    cookie = _cookie();
    when(() => client.postForm(any(),
            fields: any(named: 'fields'),
            sessionCookie: any(named: 'sessionCookie')))
        .thenAnswer((_) async => {});
    when(() => client.save(any(), any())).thenAnswer((_) async {});
    when(() => client.unsave(any(), any())).thenAnswer((_) async {});
    when(() => client.hide(any(), any())).thenAnswer((_) async {});
    when(() => client.unhide(any(), any())).thenAnswer((_) async {});
    when(() => client.deleteContent(any(), any())).thenAnswer((_) async {});
    when(() => client.editContent(
          thingId: any(named: 'thingId'),
          text: any(named: 'text'),
          sessionCookie: any(named: 'sessionCookie'),
        )).thenAnswer((_) async {});

    notifier = PostActionsNotifier(client, cookie);
  });

  test('keeps optimistic vote on failure', () async {
    when(() => client.postForm(any(),
            fields: any(named: 'fields'),
            sessionCookie: any(named: 'sessionCookie')))
        .thenThrow(Exception('vote failed'));

    await notifier.vote('t3_post', VoteDirection.upvote);
    await Future<void>.delayed(Duration.zero);

    expect(notifier.effectiveVote('t3_post', VoteDirection.none),
        VoteDirection.upvote);
  });

  test('reverts save on failure', () async {
    when(() => client.save(any(), any())).thenThrow(
        const RedditApiException(statusCode: 403, message: 'Forbidden'));

    await expectLater(
      () => notifier.toggleSave('t3_post'),
      throwsA(isA<SaveException>()),
    );
    expect(notifier.effectiveSaved('t3_post', false), false);
  });

  test('hide and unhide work correctly', () async {
    await notifier.hide('t3_post');
    expect(notifier.state.hides['t3_post'], true);

    await notifier.unhide('t3_post');
    expect(notifier.state.hides['t3_post'], isNull);
    verify(() => client.unhide('t3_post', cookie)).called(1);
  });

  test('delete routes to client', () async {
    await notifier.delete('t3_post');
    verify(() => client.deleteContent('t3_post', cookie)).called(1);
  });

  test('edit routes to client', () async {
    await notifier.edit('t3_post', 'updated text');
    verify(() => client.editContent(
          thingId: 't3_post',
          text: 'updated text',
          sessionCookie: cookie,
        )).called(1);
  });
}
