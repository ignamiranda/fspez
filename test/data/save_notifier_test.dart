import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/save_notifier.dart';
import 'package:fspez/src/data/reddit_client.dart';
import 'package:fspez/src/domain/models/session_cookie.dart';
import 'package:mocktail/mocktail.dart';

class _MockRedditClient extends Mock implements RedditClient {}

SessionCookie _makeCookie() {
  return SessionCookie(
    value: 'abc',
    expiresAt: DateTime.now().add(const Duration(days: 1)),
  );
}

void main() {
  late _MockRedditClient mockClient;
  late SaveNotifier notifier;
  final cookie = _makeCookie();

  setUpAll(() {
    registerFallbackValue(cookie);
  });

  setUp(() {
    mockClient = _MockRedditClient();
    when(() => mockClient.save(any(), any())).thenAnswer((_) async {});
    when(() => mockClient.unsave(any(), any())).thenAnswer((_) async {});
    notifier = SaveNotifier(mockClient, cookie);
  });

  group('toggle', () {
    test('toggles from unsaved to saved', () async {
      await notifier.toggle('t3_post1');
      expect(notifier.state['t3_post1'], true);
    });

    test('toggles from saved to unsaved', () async {
      await notifier.toggle('t3_post1');
      await notifier.toggle('t3_post1');
      expect(notifier.state['t3_post1'], false);
    });

    test('calls save when toggling to saved', () async {
      await notifier.toggle('t3_post1');

      verify(() => mockClient.save('t3_post1', cookie)).called(1);
    });

    test('calls unsave when toggling to unsaved', () async {
      await notifier.toggle('t3_post1');
      await notifier.toggle('t3_post1');

      verify(() => mockClient.unsave('t3_post1', cookie)).called(1);
    });

    test('maintains separate state for different fullnames', () async {
      await notifier.toggle('t3_post1');
      await notifier.toggle('t3_post2');

      expect(notifier.state['t3_post1'], true);
      expect(notifier.state['t3_post2'], true);
    });

    test('reverts optimistic state and rethrows on client error', () async {
      when(() => mockClient.save(any(), any()))
          .thenThrow(const RedditApiException(statusCode: 403, message: 'Forbidden'));

      expect(notifier.state['t3_post1'], isNull);
      await expectLater(
        () => notifier.toggle('t3_post1'),
        throwsA(isA<SaveException>()),
      );
      expect(notifier.state['t3_post1'], false);
    });

    test('throws SaveException when no session', () async {
      final noSession = SaveNotifier(mockClient, null);
      await expectLater(
        () => noSession.toggle('t3_post1'),
        throwsA(isA<SaveException>()),
      );
    });
  });

  group('effectiveSaved', () {
    test('returns override when present', () async {
      await notifier.toggle('t3_p1');
      expect(notifier.effectiveSaved('t3_p1', false), true);
    });

    test('returns original when no override', () {
      expect(notifier.effectiveSaved('t3_unknown', true), true);
      expect(notifier.effectiveSaved('t3_unknown', false), false);
    });

    test('returns original after toggle back', () async {
      await notifier.toggle('t3_p1');
      await notifier.toggle('t3_p1');
      expect(notifier.effectiveSaved('t3_p1', false), false);
    });
  });
}
