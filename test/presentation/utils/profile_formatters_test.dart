import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/presentation/utils/profile_formatters.dart';

void main() {
  group('formatRedditAccountAge', () {
    test('formats days under one month', () {
      final now = DateTime.utc(2026, 6, 1);

      expect(
        formatRedditAccountAge(DateTime.utc(2026, 5, 20), now: now),
        'Redditor for 12 days',
      );
    });

    test('formats months under one year', () {
      final now = DateTime.utc(2026, 6, 1);

      expect(
        formatRedditAccountAge(DateTime.utc(2025, 12, 1), now: now),
        'Redditor for 6 months',
      );
    });

    test('formats years for long-lived accounts', () {
      final now = DateTime.utc(2026, 6, 1);

      expect(
        formatRedditAccountAge(DateTime.utc(2022, 6, 1), now: now),
        'Redditor for 4 years',
      );
    });

    test('formats brand-new accounts gracefully', () {
      final now = DateTime.utc(2026, 6, 1);

      expect(
        formatRedditAccountAge(DateTime.utc(2026, 6, 1), now: now),
        'Redditor for 0 days',
      );
    });
  });

  test('formats profile karma breakdown with zero values', () {
    expect(
      formatProfileKarmaBreakdown(0, 1530),
      'Post karma: 0 · Comment karma: 1.5K',
    );
  });
}
