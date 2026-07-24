import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/media_client.dart';
import 'package:fspez/src/data/submit_client.dart';
import 'package:fspez/src/data/submit_notifier.dart';
import 'package:fspez/src/domain/models/session_cookie.dart';
import 'package:mocktail/mocktail.dart';

class _MockSubmitClient extends Mock implements SubmitClient {}

class _MockMediaUploadClient extends Mock implements MediaUploadClient {}

void main() {
  late _MockSubmitClient submitClient;
  late _MockMediaUploadClient mediaClient;
  late SubmitNotifier notifier;

  setUpAll(() {
    registerFallbackValue(SessionCookie(
      value: 'fallback',
      expiresAt: DateTime.utc(2099),
    ));
    registerFallbackValue(<String, String>{});
  });

  setUp(() {
    submitClient = _MockSubmitClient();
    mediaClient = _MockMediaUploadClient();
    notifier = SubmitNotifier(submitClient, mediaClient);
  });

  group('state management', () {
    test('initial state has default values', () {
      expect(notifier.state.isSubmitting, isFalse);
      expect(notifier.state.error, isNull);
      expect(notifier.state.success, isFalse);
    });

    test('reset clears all state', () {
      notifier.state = notifier.state.copyWith(
        isSubmitting: true,
        error: 'some error',
      );

      notifier.reset();

      expect(notifier.state.isSubmitting, isFalse);
      expect(notifier.state.error, isNull);
    });
  });

  group('canSubmit', () {
    test('returns true when not submitting', () {
      expect(notifier.canSubmit, isTrue);
    });

    test('returns false while submitting', () {
      notifier.state = notifier.state.copyWith(isSubmitting: true);
      expect(notifier.canSubmit, isFalse);
    });
  });

  group('submit', () {
    final cookie = SessionCookie(
      value: 'session',
      expiresAt: DateTime.utc(2099),
    );

    test('returns false when canSubmit is false', () async {
      notifier.state = notifier.state.copyWith(isSubmitting: true);

      final result = await notifier.submit(fields: {}, sessionCookie: cookie);

      expect(result, isFalse);
      verifyNever(() => submitClient.submit(
          fields: any(named: 'fields'),
          sessionCookie: any(named: 'sessionCookie')));
    });

    test('submits fields and returns true on success', () async {
      when(() => submitClient.submit(
              fields: any(named: 'fields'),
              sessionCookie: any(named: 'sessionCookie')))
          .thenAnswer((_) async => {});

      final result = await notifier.submit(
        fields: {'kind': 'self', 'sr': 'test'},
        sessionCookie: cookie,
      );

      expect(result, isTrue);
      expect(notifier.state.success, isTrue);
      verify(() => submitClient.submit(
          fields: {'kind': 'self', 'sr': 'test'},
          sessionCookie: cookie)).called(1);
    });

    test('returns false and sets error on failure', () async {
      when(() => submitClient.submit(
              fields: any(named: 'fields'),
              sessionCookie: any(named: 'sessionCookie')))
          .thenThrow(Exception('submit failed'));

      final result = await notifier.submit(
        fields: {'kind': 'self', 'sr': 'test'},
        sessionCookie: cookie,
      );

      expect(result, isFalse);
      expect(notifier.state.error, isNotNull);
      expect(notifier.state.isSubmitting, isFalse);
    });
  });

  group('submitText', () {
    final cookie = SessionCookie(
      value: 'session',
      expiresAt: DateTime.utc(2099),
      modhash: 'mh123',
    );

    test('builds self fields and calls submit', () async {
      when(() => submitClient.submit(
              fields: any(named: 'fields'),
              sessionCookie: any(named: 'sessionCookie')))
          .thenAnswer((_) async => {});

      final result = await notifier.submitText(
        title: 'My Post',
        subreddit: 'flutter',
        text: 'Hello',
        sessionCookie: cookie,
      );

      expect(result, isTrue);
      verify(() => submitClient.submit(fields: {
            'kind': 'self',
            'sr': 'flutter',
            'title': 'My Post',
            'uh': 'mh123',
            'text': 'Hello',
          }, sessionCookie: cookie)).called(1);
    });

    test('omits text field when empty', () async {
      when(() => submitClient.submit(
              fields: any(named: 'fields'),
              sessionCookie: any(named: 'sessionCookie')))
          .thenAnswer((_) async => {});

      await notifier.submitText(
        title: 'Title',
        subreddit: 'flutter',
        text: '',
        sessionCookie: cookie,
      );

      verify(() => submitClient.submit(fields: {
            'kind': 'self',
            'sr': 'flutter',
            'title': 'Title',
            'uh': 'mh123',
          }, sessionCookie: cookie)).called(1);
    });
  });

  group('submitLink', () {
    final cookie = SessionCookie(
      value: 'session',
      expiresAt: DateTime.utc(2099),
      modhash: 'mh456',
    );

    test('builds link fields and calls submit', () async {
      when(() => submitClient.submit(
              fields: any(named: 'fields'),
              sessionCookie: any(named: 'sessionCookie')))
          .thenAnswer((_) async => {});

      await notifier.submitLink(
        title: 'Cool Link',
        subreddit: 'flutter',
        url: 'https://example.com',
        sessionCookie: cookie,
      );

      verify(() => submitClient.submit(fields: {
            'kind': 'link',
            'sr': 'flutter',
            'title': 'Cool Link',
            'uh': 'mh456',
            'url': 'https://example.com',
          }, sessionCookie: cookie)).called(1);
    });
  });
}
