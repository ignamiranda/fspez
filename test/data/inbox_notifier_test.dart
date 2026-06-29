import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/inbox_notifier.dart';
import 'package:fspez/src/data/inbox_repository.dart';
import 'package:fspez/src/domain/models/account.dart';
import 'package:fspez/src/domain/models/inbox_item.dart';
import 'package:fspez/src/domain/models/inbox_feed.dart';
import 'package:fspez/src/domain/models/session_cookie.dart';
import 'package:mocktail/mocktail.dart';

class _MockInboxRepository extends Mock implements InboxRepository {}

class _TestInboxNotifier extends InboxNotifier {
  int refreshUnreadCountCalls = 0;

  _TestInboxNotifier(super.repository, super.account) : super(autoLoad: false);

  @override
  Future<void> refreshUnreadCount() async {
    refreshUnreadCountCalls++;
    await super.refreshUnreadCount();
  }
}

DirectMessage _message({required bool isNew}) => DirectMessage(
      id: 'm1',
      subject: 'Subject',
      body: 'Body',
      author: 'alice',
      dest: 'bob',
      createdAt: DateTime.utc(2024, 1, 1),
      isNew: isNew,
    );

void main() {
  late _MockInboxRepository repository;
  late SessionCookie cookie;
  late Account account;

  setUpAll(() {
    registerFallbackValue(SessionCookie(
      value: 'fallback',
      expiresAt: DateTime.utc(2099),
    ));
  });

  setUp(() {
    repository = _MockInboxRepository();
    cookie = SessionCookie(
      value: 'session_val',
      expiresAt: DateTime.utc(2099),
      rawCookie: 'reddit_session=session_val',
      modhash: 'modhash123',
    );
    account = Account(id: 'u1', username: 'alice', sessionCookie: cookie);
  });

  group('refreshUnreadCount', () {
    test('fetches unread count and stores badge value', () async {
      when(() => repository.fetchUnread(sessionCookie: cookie)).thenAnswer(
        (_) async => InboxFeed(
          tab: InboxTab.unread,
          items: [
            _message(isNew: true),
            DirectMessage(
              id: 'm2',
              subject: 'Subject',
              body: 'Body',
              author: 'alice',
              dest: 'bob',
              createdAt: DateTime.utc(2024, 1, 1),
              isNew: true,
            ),
          ],
        ),
      );

      final notifier = _TestInboxNotifier(repository, account);

      await notifier.refreshUnreadCount();

      expect(notifier.state.unreadCount, 2);
      verify(() => repository.fetchUnread(sessionCookie: cookie)).called(1);
    });

    test('keeps existing badge value when fetch fails', () async {
      when(() => repository.fetchUnread(sessionCookie: cookie))
          .thenThrow(Exception('boom'));

      final notifier = _TestInboxNotifier(repository, account)
        ..state = const InboxState(unreadCount: 7);

      await notifier.refreshUnreadCount();

      expect(notifier.state.unreadCount, 7);
    });
  });

  group('markAsRead', () {
    test('optimistically clears isNew and decrements unreadCount', () async {
      final message = _message(isNew: true);
      final notifier = _TestInboxNotifier(repository, account)
        ..state = InboxState(
          tab: InboxTab.all,
          messages: [message],
          unreadCount: 3,
        );

      when(() => repository.markAsRead(message.fullname, cookie))
          .thenAnswer((_) async {});

      await notifier.markAsRead(message);

      expect(notifier.state.unreadCount, 2);
      expect(notifier.state.messages.single.isNew, false);
      verify(() => repository.markAsRead(message.fullname, cookie)).called(1);
    });

    test('restores state and refreshes after repository failure', () async {
      final message = _message(isNew: true);
      final notifier = _TestInboxNotifier(repository, account)
        ..state = InboxState(
          tab: InboxTab.all,
          messages: [message],
          unreadCount: 3,
        );

      when(() => repository.markAsRead(message.fullname, cookie))
          .thenThrow(Exception('boom'));
      when(() => repository.fetchInbox(
            after: any(named: 'after'),
            sessionCookie: cookie,
          )).thenAnswer(
        (_) async => InboxFeed(
          tab: InboxTab.all,
          items: [_message(isNew: true)],
        ),
      );
      when(() => repository.fetchUnread(sessionCookie: cookie)).thenAnswer(
        (_) async => InboxFeed(
          tab: InboxTab.unread,
          items: [_message(isNew: true)],
        ),
      );

      await expectLater(
        notifier.markAsRead(message),
        throwsA(isA<Exception>()),
      );

      expect(notifier.state.unreadCount, 1);
      expect(notifier.state.messages.single.isNew, true);
      verify(() => repository.fetchInbox(
            after: any(named: 'after'),
            sessionCookie: cookie,
          )).called(1);
    });
  });
}
