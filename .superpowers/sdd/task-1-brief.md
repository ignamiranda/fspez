### Task 1: AccountRepository — error-tolerant storage reads

**Files:**
- Modify: `lib/src/data/account_repository.dart` — wrap `_storage.read()` calls in try/catch for `PlatformException`
- Modify: `test/data/account_repository_test.dart` — add tests for corrupted storage

**Interfaces:**
- Consumes: `FakeSecureStorage` (existing test helper)
- Produces: `AccountRepository` methods (`loadAll`, `loadActive`, `remove`) return null/empty on read failure

- [ ] **Step 1: Add error handling to `loadAll()`**

Wrap line 15 (`final json = await _storage.read(key: _accountsKey);`):

```dart
  Future<List<Account>> loadAll() async {
    String? json;
    try {
      json = await _storage.read(key: _accountsKey);
    } on PlatformException {
      await _storage.delete(key: _accountsKey);
      return [];
    }
    if (json == null) return [];

    final list = jsonDecode(json) as List<dynamic>;
    return list.map((item) {
      ...
    }).toList();
  }
```

Add import at top: `import 'package:flutter/foundation.dart';` (for `PlatformException`)

- [ ] **Step 2: Add error handling to `loadActive()`**

Wrap line 80 (`final activeId = await _storage.read(key: _activeAccountIdKey);`):

```dart
  Future<Account?> loadActive() async {
    String? activeId;
    try {
      activeId = await _storage.read(key: _activeAccountIdKey);
    } on PlatformException {
      return null;
    }
    if (activeId == null) return null;
    final all = await loadAll();
    return all.where((a) => a.id == activeId).firstOrNull;
  }
```

- [ ] **Step 3: Add error handling to `remove()`**

Wrap line 69 (`final activeId = await _storage.read(key: _activeAccountIdKey);`):

```dart
  Future<void> remove(String accountId) async {
    final accounts = await loadAll();
    final remaining = accounts.where((a) => a.id != accountId).toList();
    await _persistAll(remaining);

    String? activeId;
    try {
      activeId = await _storage.read(key: _activeAccountIdKey);
    } on PlatformException {
      return;
    }
    if (activeId == accountId) {
      await _storage.delete(key: _activeAccountIdKey);
    }
  }
```

- [ ] **Step 4: Write tests for corrupted storage**

Add `ThrowingSecureStorage` class and test group to `test/data/account_repository_test.dart`:

```dart
import 'package:flutter/foundation.dart';

class ThrowingSecureStorage extends FakeSecureStorage {
  @override
  Future<String?> read({required String key, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async {
    throw PlatformException(code: 'read', message: 'BadPaddingException: error:1e000065');
  }
}
```

Test group:

```dart
  group('corrupted storage', () {
    test('loadAll returns empty list when storage throws', () async {
      final repo = AccountRepository(ThrowingSecureStorage());
      final accounts = await repo.loadAll();
      expect(accounts, isEmpty);
    });

    test('loadActive returns null when storage throws', () async {
      final repo = AccountRepository(ThrowingSecureStorage());
      final active = await repo.loadActive();
      expect(active, isNull);
    });

    test('remove does not throw when storage throws', () async {
      final repo = AccountRepository(ThrowingSecureStorage());
      await expectLater(repo.remove('a1'), completes);
    });
  });
```

- [ ] **Step 5: Run tests**

```bash
flutter test test/data/account_repository_test.dart
```

Expected: All tests pass (existing + 3 new corrupted storage tests).

- [ ] **Step 6: Commit**

```bash
git add lib/src/data/account_repository.dart test/data/account_repository_test.dart
git commit -m "fix: handle PlatformException on FlutterSecureStorage read in AccountRepository"
```
