# Fix Sign-In Crash on Corrupted Secure Storage (Issue #24) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prevent `PlatformException(BadPaddingException)` from crashing the sign-in flow on Android by catching storage read errors, recovering gracefully, and informing the user.

**Architecture:** Catch `FlutterSecureStorage.read()` errors in `AccountRepository` and return null/empty. Wrap `ActiveAccountNotifier._init()` in try/catch. Add a `corruptedSessionProvider` (bool) to signal the UI. `_AppGate` listens and shows a snackbar.

**Tech Stack:** Flutter, Riverpod 2.5+, flutter_secure_storage, mocktail (tests)

## Global Constraints

- Use `StateProvider<bool>` for corrupted session signal (matching existing `guestModeProvider` pattern)
- Use mocktail for test mocks (existing project convention)
- `FakeSecureStorage` already exists in `test/data/account_repository_test.dart`
- Write errors (`_storage.write()`) propagate — only catch read errors
- All 239 existing tests must pass after changes

---

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

- [ ] **Step 4: Write tests for corrupted storage in `account_repository_test.dart`**

Add to the test file:

```dart
import 'package:flutter/foundation.dart';

// In FakeSecureStorage, add a mode to throw on read:
class ThrowingSecureStorage extends FakeSecureStorage {
  @override
  Future<String?> read({required String key, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async {
    throw PlatformException(code: 'read', message: 'BadPaddingException: error:1e000065');
  }
}
```

Add test group:

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

### Task 2: ActiveAccountNotifier — startup error boundary + corruptedSessionProvider

**Files:**
- Create: `test/data/account_notifier_test.dart`
- Modify: `lib/src/data/auth_providers.dart` — add `corruptedSessionProvider`
- Modify: `lib/src/data/account_notifier.dart` — wrap `_init()` in try/catch, set corrupted state

**Interfaces:**
- Consumes: `AccountRepository`, `AccountListVersionNotifier`, `FeedCache`, and now `StateController<bool>` (corruptedSession)
- Produces: `corruptedSessionProvider` (StateProvider<bool>)

- [ ] **Step 1: Add `corruptedSessionProvider` to `auth_providers.dart`**

After the `activeAccountProvider` definition, add:

```dart
final corruptedSessionProvider = StateProvider<bool>((ref) => false);
```

- [ ] **Step 2: Update `ActiveAccountNotifier` to accept corrupted state controller**

Add import at top of `account_notifier.dart`:
```dart
import 'package:flutter/foundation.dart';
```

Update constructor:
```dart
class ActiveAccountNotifier extends StateNotifier<Account?> {
  final AccountRepository _repository;
  final AccountListVersionNotifier _listVersion;
  final FeedCache _feedCache;
  final StateController<bool> _corruptedSession;

  ActiveAccountNotifier(
    this._repository,
    this._listVersion,
    this._feedCache,
    this._corruptedSession,
  ) : super(null) {
    Future.microtask(_init);
  }
```

- [ ] **Step 3: Wrap `_init()` in try/catch**

```dart
  Future<void> _init() async {
    try {
      state = await _repository.loadActive();
      await _deduplicate();
    } catch (e) {
      _corruptedSession.state = true;
      debugPrint('Failed to load active account: $e');
    }
  }
```

- [ ] **Step 4: Update `activeAccountProvider` to pass corrupted session controller**

In `auth_providers.dart`:

```dart
final activeAccountProvider =
    StateNotifierProvider<ActiveAccountNotifier, Account?>((ref) {
  return ActiveAccountNotifier(
    ref.watch(accountRepositoryProvider),
    ref.watch(accountListVersionProvider.notifier),
    ref.watch(feedCacheProvider),
    ref.watch(corruptedSessionProvider.notifier),
  );
});
```

- [ ] **Step 5: Write tests for corrupted session handling**

Create `test/data/account_notifier_test.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/account_notifier.dart';
import 'package:fspez/src/data/account_repository.dart';
import 'package:fspez/src/data/auth_providers.dart';
import 'package:fspez/src/data/feed_cache.dart';
import 'package:fspez/src/domain/models/account.dart';
import 'package:fspez/src/domain/models/session_cookie.dart';
import 'account_repository_test.dart' show FakeSecureStorage;

class ThrowingAccountRepository extends AccountRepository {
  ThrowingAccountRepository() : super(FakeSecureStorage());

  @override
  Future<Account?> loadActive() async {
    throw PlatformException(code: 'read', message: 'BadPaddingException');
  }

  @override
  Future<List<Account>> loadAll() async {
    throw PlatformException(code: 'read', message: 'BadPaddingException');
  }
}

void main() {
  group('ActiveAccountNotifier corrupted storage', () {
    test('falls back to null state on PlatformException', () async {
      final corrupted = StateProvider<bool>((ref) => false);
      final container = ProviderContainer();
      final notifier = ActiveAccountNotifier(
        ThrowingAccountRepository(),
        AccountListVersionNotifier(),
        FeedCache(),
        container.read(corrupted.notifier),
      );

      // Wait for microtask (_init)
      await Future(() {});
      await Future(() {});

      expect(notifier.state, isNull);
      expect(container.read(corrupted), isTrue);
      container.dispose();
    });
  });
}
```

- [ ] **Step 6: Run tests**

```bash
flutter test test/data/account_notifier_test.dart
```

Expected: 1 test passes.

- [ ] **Step 7: Run full test suite**

```bash
flutter test
```

Expected: All tests pass.

- [ ] **Step 8: Commit**

```bash
git add lib/src/data/account_notifier.dart lib/src/data/auth_providers.dart test/data/account_notifier_test.dart
git commit -m "fix: add startup error boundary in ActiveAccountNotifier + corruptedSessionProvider"
```

### Task 3: _AppGate — user-facing error feedback

**Files:**
- Modify: `lib/src/presentation/app.dart` — listen to `corruptedSessionProvider`, show snackbar

**Interfaces:**
- Consumes: `corruptedSessionProvider` from `auth_providers.dart`

- [ ] **Step 1: Add snackbar listener for corrupted session in `_AppGateState.build()`**

In `_AppGateState`, before the existing `ref.listen(sessionHealthProvider, ...)`:

```dart
    ref.listen<bool>(corruptedSessionProvider, (prev, next) {
      if (next == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Saved session data was corrupted. Please sign in again.',
              ),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Dismiss',
                onPressed: () =>
                    ref.read(corruptedSessionProvider.notifier).state = false,
              ),
            ),
          );
        });
      }
    });
```

Add import: `import '../data/auth_providers.dart';` (if not already there — it is imported at line 11).

- [ ] **Step 2: Verify the app builds**

```bash
flutter analyze --no-pub
```

Expected: Clean analysis, no errors.

- [ ] **Step 3: Run full test suite**

```bash
flutter test
```

Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/src/presentation/app.dart
git commit -m "feat: show snackbar when corrupted session data is detected"
```
