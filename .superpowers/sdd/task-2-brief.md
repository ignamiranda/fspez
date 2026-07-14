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
