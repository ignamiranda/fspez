import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/cookie_parser.dart';

void main() {
  late CookieParser parser;

  setUp(() {
    parser = CookieParser();
  });

  group('parseCookie', () {
    test('extracts reddit_session from document.cookie', () {
      final cookie = parser.parseCookie(
        'reddit_session=abc123; loggedin=1;',
      );

      expect(cookie, isNotNull);
      expect(cookie!.value, 'abc123');
    });

    test('returns null when no reddit_session present', () {
      final cookie = parser.parseCookie('loggedin=1;');

      expect(cookie, isNull);
    });

    test('returns null for empty string', () {
      final cookie = parser.parseCookie('');

      expect(cookie, isNull);
    });
  });

  group('extractUsername', () {
    test('falls back to generic name for unrecognisable cookie', () {
      final username = parser.extractUsername('garbage');

      expect(username, startsWith('user_'));
    });

    test('returns generic fallback on empty input', () {
      final username = parser.extractUsername('');

      expect(username, 'unknown');
    });
  });
}
