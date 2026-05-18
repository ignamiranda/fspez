import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/domain/models/account.dart';
import 'package:fspez/src/domain/models/session_cookie.dart';

void main() {
  group('SessionCookie', () {
    test('isExpired returns false for future date', () {
      final cookie = SessionCookie(
        value: 'test_cookie',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );
      expect(cookie.isExpired, false);
    });

    test('isExpired returns true for past date', () {
      final cookie = SessionCookie(
        value: 'test_cookie',
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(cookie.isExpired, true);
    });
  });

  group('Account', () {
    test('equality works by value', () {
      final cookie = SessionCookie(
        value: 'abc',
        expiresAt: DateTime(2026),
      );
      final a1 = Account(id: '1', username: 'test', sessionCookie: cookie);
      final a2 = Account(id: '1', username: 'test', sessionCookie: cookie);
      expect(a1, equals(a2));
    });

    test('different ids are not equal', () {
      final cookie = SessionCookie(
        value: 'abc',
        expiresAt: DateTime(2026),
      );
      final a1 = Account(id: '1', username: 'test', sessionCookie: cookie);
      final a2 = Account(id: '2', username: 'test', sessionCookie: cookie);
      expect(a1, isNot(equals(a2)));
    });
  });
}
