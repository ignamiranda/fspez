import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/account_repository.dart';
import 'package:fspez/src/domain/models/account.dart';
import 'package:fspez/src/domain/models/session_cookie.dart';

class FakeSecureStorage extends FlutterSecureStorage {
  final _store = <String, String>{};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _store[key] = value;
    } else {
      _store.remove(key);
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _store[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.remove(key);
  }
}

void main() {
  late FakeSecureStorage storage;
  late AccountRepository repository;

  setUp(() {
    storage = FakeSecureStorage();
    repository = AccountRepository(storage);
  });

  group('loadAll / save', () {
    test('loadAll returns empty list when no accounts stored', () async {
      final accounts = await repository.loadAll();
      expect(accounts, isEmpty);
    });

    test('save and loadAll round-trips an account', () async {
      final account = Account(
        id: 'a1',
        username: 'user1',
        sessionCookie: SessionCookie(
          value: 'cookie_val',
          expiresAt: DateTime(2026, 1, 1),
        ),
      );

      await repository.save(account);
      final accounts = await repository.loadAll();

      expect(accounts.length, 1);
      expect(accounts[0].id, 'a1');
      expect(accounts[0].username, 'user1');
      expect(accounts[0].sessionCookie.value, 'cookie_val');
    });

    test('save updates existing account by id', () async {
      final account = Account(
        id: 'a1',
        username: 'user1',
        sessionCookie: SessionCookie(
          value: 'cookie_val',
          expiresAt: DateTime(2026, 1, 1),
        ),
      );

      await repository.save(account);

      final updated = Account(
        id: 'a1',
        username: 'user1',
        sessionCookie: SessionCookie(
          value: 'new_cookie',
          expiresAt: DateTime(2027, 1, 1),
        ),
      );

      await repository.save(updated);
      final accounts = await repository.loadAll();

      expect(accounts.length, 1);
      expect(accounts[0].sessionCookie.value, 'new_cookie');
    });

    test('save updates existing account by username when id differs',
        () async {
      await repository.save(Account(
        id: 'a1',
        username: 'user1',
        sessionCookie: SessionCookie(
          value: 'cookie_val',
          expiresAt: DateTime(2026, 1, 1),
        ),
      ));

      await repository.save(Account(
        id: 'a2',
        username: 'user1',
        sessionCookie: SessionCookie(
          value: 'updated_cookie',
          expiresAt: DateTime(2026, 1, 1),
        ),
      ));

      final accounts = await repository.loadAll();

      expect(accounts.length, 1);
      expect(accounts[0].id, 'a2');
      expect(accounts[0].sessionCookie.value, 'updated_cookie');
    });

    test('save adds new account when id and username are both new', () async {
      await repository.save(Account(
        id: 'a1',
        username: 'user1',
        sessionCookie: SessionCookie(
          value: 'cookie1',
          expiresAt: DateTime(2026, 1, 1),
        ),
      ));

      await repository.save(Account(
        id: 'a2',
        username: 'user2',
        sessionCookie: SessionCookie(
          value: 'cookie2',
          expiresAt: DateTime(2026, 1, 1),
        ),
      ));

      final accounts = await repository.loadAll();

      expect(accounts.length, 2);
    });

    test('round-trips optional fields rawCookie and modhash', () async {
      final account = Account(
        id: 'a1',
        username: 'user1',
        sessionCookie: SessionCookie(
          value: 'cookie_val',
          expiresAt: DateTime(2026, 1, 1),
          rawCookie: 'reddit_session=cookie_val; loggedin=1',
          modhash: 'mh123',
        ),
      );

      await repository.save(account);
      final accounts = await repository.loadAll();

      expect(accounts[0].sessionCookie.rawCookie,
          'reddit_session=cookie_val; loggedin=1');
      expect(accounts[0].sessionCookie.modhash, 'mh123');
    });
  });

  group('remove', () {
    test('removes account by id and keeps others', () async {
      await repository.save(Account(
        id: 'a1',
        username: 'user1',
        sessionCookie: SessionCookie(
          value: 'cookie1',
          expiresAt: DateTime(2026, 1, 1),
        ),
      ));

      await repository.save(Account(
        id: 'a2',
        username: 'user2',
        sessionCookie: SessionCookie(
          value: 'cookie2',
          expiresAt: DateTime(2026, 1, 1),
        ),
      ));

      await repository.remove('a1');
      final accounts = await repository.loadAll();

      expect(accounts.length, 1);
      expect(accounts[0].id, 'a2');
    });

    test('remove clears active account id when removed account was active',
        () async {
      await repository.save(Account(
        id: 'a1',
        username: 'user1',
        sessionCookie: SessionCookie(
          value: 'cookie1',
          expiresAt: DateTime(2026, 1, 1),
        ),
      ));

      await repository.setActive('a1');
      await repository.remove('a1');

      final active = await repository.loadActive();
      expect(active, isNull);
    });

    test('remove keeps active account id when removed account was not active',
        () async {
      await repository.save(Account(
        id: 'a1',
        username: 'user1',
        sessionCookie: SessionCookie(
          value: 'cookie1',
          expiresAt: DateTime(2026, 1, 1),
        ),
      ));

      await repository.save(Account(
        id: 'a2',
        username: 'user2',
        sessionCookie: SessionCookie(
          value: 'cookie2',
          expiresAt: DateTime(2026, 1, 1),
        ),
      ));

      await repository.setActive('a1');
      await repository.remove('a2');

      final active = await repository.loadActive();
      expect(active?.id, 'a1');
    });
  });

  group('setActive / loadActive', () {
    test('loadActive returns null when no active account set', () async {
      final active = await repository.loadActive();
      expect(active, isNull);
    });

    test('setActive and loadActive round-trips', () async {
      final account = Account(
        id: 'a1',
        username: 'user1',
        sessionCookie: SessionCookie(
          value: 'cookie1',
          expiresAt: DateTime(2026, 1, 1),
        ),
      );

      await repository.save(account);
      await repository.setActive('a1');

      final active = await repository.loadActive();
      expect(active?.id, 'a1');
      expect(active?.username, 'user1');
    });

    test(
        'loadActive returns null when active account is not in accounts list',
        () async {
      await repository.setActive('nonexistent');
      final active = await repository.loadActive();
      expect(active, isNull);
    });
  });

  group('clearAllExcept', () {
    test('removes all accounts except the specified one', () async {
      await repository.save(Account(
        id: 'a1',
        username: 'user1',
        sessionCookie: SessionCookie(
          value: 'cookie1',
          expiresAt: DateTime(2026, 1, 1),
        ),
      ));

      await repository.save(Account(
        id: 'a2',
        username: 'user2',
        sessionCookie: SessionCookie(
          value: 'cookie2',
          expiresAt: DateTime(2026, 1, 1),
        ),
      ));

      await repository.clearAllExcept('a1');
      final accounts = await repository.loadAll();

      expect(accounts.length, 1);
      expect(accounts[0].id, 'a1');
    });
  });

  group('replaceAll', () {
    test('replaces all accounts', () async {
      await repository.save(Account(
        id: 'a1',
        username: 'user1',
        sessionCookie: SessionCookie(
          value: 'cookie1',
          expiresAt: DateTime(2026, 1, 1),
        ),
      ));

      final replacement = [
        Account(
          id: 'b1',
          username: 'newuser',
          sessionCookie: SessionCookie(
            value: 'new_cookie',
            expiresAt: DateTime(2026, 1, 1),
          ),
        ),
      ];

      await repository.replaceAll(replacement);
      final accounts = await repository.loadAll();

      expect(accounts.length, 1);
      expect(accounts[0].id, 'b1');
      expect(accounts[0].username, 'newuser');
    });

    test('replaceAll with empty list clears all accounts', () async {
      await repository.save(Account(
        id: 'a1',
        username: 'user1',
        sessionCookie: SessionCookie(
          value: 'cookie1',
          expiresAt: DateTime(2026, 1, 1),
        ),
      ));

      await repository.replaceAll([]);
      final accounts = await repository.loadAll();

      expect(accounts, isEmpty);
    });
  });
}
