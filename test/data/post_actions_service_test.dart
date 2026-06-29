import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/action_notifier.dart';
import 'package:fspez/src/data/edit_notifier.dart';
import 'package:fspez/src/data/post_actions_service.dart';
import 'package:fspez/src/data/reddit_client.dart';
import 'package:fspez/src/data/interaction_client.dart';
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
  late _MockInteractionClient client;
  late SessionCookie cookie;
  late ActionNotifier<VoteDirection> voteNotifier;
  late ActionNotifier<bool> saveNotifier;
  late ActionNotifier<bool> hideNotifier;
  late ActionNotifier<void> deleteNotifier;
  late EditNotifier editNotifier;
  late PostActionsService service;

  setUpAll(() {
    registerFallbackValue(_cookie());
  });

  setUp(() {
    client = _MockInteractionClient();
    cookie = _cookie();
    when(() => client.vote(
          fullname: any(named: 'fullname'),
          direction: any(named: 'direction'),
          sessionCookie: any(named: 'sessionCookie'),
        )).thenAnswer((_) async {});
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

    voteNotifier = ActionNotifier<VoteDirection>(cookie);
    saveNotifier = ActionNotifier<bool>(cookie);
    hideNotifier = ActionNotifier<bool>(cookie);
    deleteNotifier = ActionNotifier<void>(cookie);
    editNotifier = EditNotifier(client);
    service = PostActionsService(
      voteNotifier: voteNotifier,
      saveNotifier: saveNotifier,
      hideNotifier: hideNotifier,
      deleteNotifier: deleteNotifier,
      editNotifier: editNotifier,
      client: client,
      sessionCookie: cookie,
    );
  });

  test('routes votes through ActionNotifier and keeps optimistic failures',
      () async {
    when(() => client.vote(
          fullname: any(named: 'fullname'),
          direction: any(named: 'direction'),
          sessionCookie: any(named: 'sessionCookie'),
        )).thenThrow(Exception('vote failed'));

    service.vote('t3_post', VoteDirection.upvote);
    await Future<void>.delayed(Duration.zero);

    expect(voteNotifier.effectiveValue('t3_post', VoteDirection.none),
        VoteDirection.upvote);
  });

  test('routes saves through ActionNotifier and rethrows after reverting',
      () async {
    when(() => client.save(any(), any())).thenThrow(
        const RedditApiException(statusCode: 403, message: 'Forbidden'));

    await expectLater(
      () => service.toggleSave('t3_post'),
      throwsA(isA<PostActionException>()),
    );
    expect(saveNotifier.effectiveValue('t3_post', false), false);
  });

  test('routes hide and unhide through ActionNotifier', () async {
    await service.hide('t3_post');
    expect(hideNotifier.state['t3_post'], true);

    await service.unhide('t3_post');
    expect(hideNotifier.state['t3_post'], true);
    verify(() => client.unhide('t3_post', cookie)).called(1);
  });

  test('routes delete through ActionNotifier with active session', () async {
    await service.delete('t3_post');

    verify(() => client.deleteContent('t3_post', cookie)).called(1);
  });

  test('routes edits through EditNotifier', () async {
    await service.edit('t3_post', 'updated text');

    verify(() => client.editContent(
          thingId: 't3_post',
          text: 'updated text',
          sessionCookie: cookie,
        )).called(1);
  });
}
