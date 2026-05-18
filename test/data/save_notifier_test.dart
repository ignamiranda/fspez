import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/save_notifier.dart';
import 'package:fspez/src/data/save_repository.dart' show SaveRepository, SaveException;
import 'package:mocktail/mocktail.dart';

class _MockSaveRepository extends Mock implements SaveRepository {}

void main() {
  late _MockSaveRepository mockRepo;
  late SaveNotifier notifier;

  setUp(() {
    mockRepo = _MockSaveRepository();
    when(() => mockRepo.save(any(), sessionCookie: any(named: 'sessionCookie')))
        .thenAnswer((_) async {});
    when(() => mockRepo.unsave(any(), sessionCookie: any(named: 'sessionCookie')))
        .thenAnswer((_) async {});
    notifier = SaveNotifier(mockRepo, null);
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

      verify(() => mockRepo.save('t3_post1', sessionCookie: null)).called(1);
    });

    test('calls unsave when toggling to unsaved', () async {
      await notifier.toggle('t3_post1');
      await notifier.toggle('t3_post1');

      verify(() => mockRepo.unsave('t3_post1', sessionCookie: null)).called(1);
    });

    test('maintains separate state for different fullnames', () async {
      await notifier.toggle('t3_post1');
      await notifier.toggle('t3_post2');

      expect(notifier.state['t3_post1'], true);
      expect(notifier.state['t3_post2'], true);
    });

    test('reverts optimistic state and rethrows on repository error', () async {
      when(() => mockRepo.save(any(), sessionCookie: any(named: 'sessionCookie')))
          .thenThrow(SaveException(statusCode: 403, body: 'Forbidden'));

      expect(notifier.state['t3_post1'], isNull);
      await expectLater(
        () => notifier.toggle('t3_post1'),
        throwsA(isA<SaveException>()),
      );
      expect(notifier.state['t3_post1'], false);
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
