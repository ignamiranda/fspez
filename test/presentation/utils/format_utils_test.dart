import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/presentation/utils/format_utils.dart';

void main() {
  group('formatCount', () {
    test('formats numbers under 1000', () {
      expect(formatCount(0), '');
      expect(formatCount(5), '5');
      expect(formatCount(999), '999');
    });

    test('formats thousands', () {
      expect(formatCount(1000), '1.0K');
      expect(formatCount(1500), '1.5K');
      expect(formatCount(999900), '999.9K');
    });

    test('formats millions', () {
      expect(formatCount(1000000), '1.0M');
      expect(formatCount(2500000), '2.5M');
    });
  });

  group('timeAgo', () {
    test('returns now for < 60 seconds', () {
      expect(timeAgo(DateTime.now()), 'now');
    });

    test('returns minutes', () {
      expect(
        timeAgo(DateTime.now().subtract(const Duration(minutes: 5))),
        '5m',
      );
    });

    test('returns hours', () {
      expect(
        timeAgo(DateTime.now().subtract(const Duration(hours: 3))),
        '3h',
      );
    });

    test('returns days', () {
      expect(
        timeAgo(DateTime.now().subtract(const Duration(days: 7))),
        '7d',
      );
    });

    test('returns months', () {
      expect(
        timeAgo(DateTime.now().subtract(const Duration(days: 60))),
        '2mo',
      );
    });

    test('returns years', () {
      expect(
        timeAgo(DateTime.now().subtract(const Duration(days: 400))),
        '1y',
      );
    });
  });
}
