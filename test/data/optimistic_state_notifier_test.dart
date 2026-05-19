import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/optimistic_state_notifier.dart';

class _ConcreteNotifier extends OptimisticStateNotifier<String, int> {
  void setValue(String key, int value) => optimisticSet(key, value);
  void revert(String key, int? previous) => optimisticRevert(key, previous);
}

void main() {
  late _ConcreteNotifier notifier;

  setUp(() {
    notifier = _ConcreteNotifier();
  });

  group('optimisticSet', () {
    test('sets value for key', () {
      notifier.setValue('a', 1);
      expect(notifier.state['a'], 1);
    });

    test('overwrites existing value', () {
      notifier.setValue('a', 1);
      notifier.setValue('a', 2);
      expect(notifier.state['a'], 2);
    });

    test('preserves other keys', () {
      notifier.setValue('a', 1);
      notifier.setValue('b', 2);
      expect(notifier.state['a'], 1);
      expect(notifier.state['b'], 2);
      expect(notifier.state.length, 2);
    });
  });

  group('effective', () {
    test('returns override when present', () {
      notifier.setValue('a', 42);
      expect(notifier.effective('a', 0), 42);
    });

    test('returns fallback when no override', () {
      expect(notifier.effective('unknown', 99), 99);
    });
  });

  group('optimisticRevert', () {
    test('restores previous value', () {
      notifier.setValue('a', 1);
      notifier.revert('a', 0);
      expect(notifier.state['a'], 0);
    });

    test('removes key when previous is null', () {
      notifier.setValue('a', 1);
      notifier.revert('a', null);
      expect(notifier.state.containsKey('a'), false);
    });

    test('preserves other keys during revert', () {
      notifier.setValue('a', 1);
      notifier.setValue('b', 2);
      notifier.revert('a', 0);
      expect(notifier.state['a'], 0);
      expect(notifier.state['b'], 2);
    });
  });
}
