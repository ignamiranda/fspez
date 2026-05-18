import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/session_store.dart';
import 'package:fspez/src/domain/models/session_cookie.dart';

class _FakeCookieProvider implements CookieProvider {
  final String? _value;
  int callCount = 0;

  _FakeCookieProvider(this._value);

  @override
  Future<String?> getRedditSessionValue() async {
    callCount++;
    return _value;
  }
}

class _DelayedCookieProvider implements CookieProvider {
  final String? _value;
  final int _readyAfterAttempt;
  int callCount = 0;

  _DelayedCookieProvider(this._value, this._readyAfterAttempt);

  @override
  Future<String?> getRedditSessionValue() async {
    callCount++;
    if (callCount >= _readyAfterAttempt) return _value;
    return null;
  }
}

void main() {
  group('SessionStore.acquire', () {
    test('returns SessionCookie when provider returns a value', () async {
      final provider = _FakeCookieProvider('abc123');
      final store = SessionStore(cookieProvider: provider);

      final cookie = await store.acquire(maxAttempts: 5);

      expect(cookie, isNotNull);
      expect(cookie!.value, 'abc123');
      expect(provider.callCount, 1);
    });

    test('returns null when provider never returns a value', () async {
      final provider = _FakeCookieProvider(null);
      final store = SessionStore(cookieProvider: provider);

      final cookie = await store.acquire(maxAttempts: 3);

      expect(cookie, isNull);
      expect(provider.callCount, 3);
    });

    test('returns value after several attempts', () async {
      final provider = _DelayedCookieProvider('abc123', 3);
      final store = SessionStore(cookieProvider: provider);

      final cookie = await store.acquire(maxAttempts: 5);

      expect(cookie, isNotNull);
      expect(cookie!.value, 'abc123');
      expect(provider.callCount, 3);
    });
  });
}
