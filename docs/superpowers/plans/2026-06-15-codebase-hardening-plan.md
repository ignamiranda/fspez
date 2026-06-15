# Codebase Hardening Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix structural debt, security gaps, and maintainability issues identified in codebase review.

**Architecture:** Eight independent tasks, each scoped to a single concern. Tasks have no ordering dependencies — can be implemented in any sequence. Each produces passing tests.

**Tech Stack:** Flutter 3.22+, Dart 3.4+, Riverpod, flutter_secure_storage

---

### Task 1: Secure cookie storage with flutter_secure_storage

**Problem:** Account session cookies (full bearer tokens) are stored as plaintext JSON in SharedPreferences. On Android this is an XML file at `/data/data/<app>/shared_prefs/` — readable by any app with root or ADB backup access.

**Solution:** Migrate account persistence from `SharedPreferences` to `flutter_secure_storage` (encrypted Keystore/Keychain). Keep `SharedPreferences` for non-sensitive settings (theme, density, comment sort).

**Files:**
- Modify: `pubspec.yaml` — add `flutter_secure_storage`
- Modify: `lib/src/data/account_repository.dart` — rewrite to use `FlutterSecureStorage`
- Modify: `lib/src/data/auth_providers.dart` — update provider wiring
- Modify: `lib/main.dart` — provider override for secure storage
- Modify: `lib/src/data/feed_cache.dart` — no change needed (cached feed data is public)
- No change: `app_settings.dart` (non-sensitive data stays in SharedPreferences)

- [ ] **Step 1: Add flutter_secure_storage dependency**

In `pubspec.yaml`, add under `dependencies`:

```yaml
  flutter_secure_storage: ^9.2.0
```

- [ ] **Step 2: Verify it compiles**

```bash
cd F:\OpenCode\fspez && flutter pub get
```

Expected: no errors. Note: on Windows `flutter_secure_storage` works via a stub — full encryption works on Android/iOS.

- [ ] **Step 3: Add secure storage provider**

In `auth_providers.dart`, add:

```dart
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  throw UnimplementedError('FlutterSecureStorage must be overridden in main');
});
```

And update `accountRepositoryProvider`:

```dart
final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(ref.watch(secureStorageProvider));
});
```

- [ ] **Step 4: Rewrite AccountRepository to use FlutterSecureStorage**

Replace the body of `lib/src/data/account_repository.dart`:

```dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/models/account.dart';
import '../domain/models/session_cookie.dart';

class AccountRepository {
  static const _accountsKey = 'fspez_accounts';
  static const _activeAccountIdKey = 'fspez_active_account_id';

  final FlutterSecureStorage _storage;

  AccountRepository(this._storage);

  Future<List<Account>> loadAll() async {
    final json = await _storage.read(key: _accountsKey);
    if (json == null) return [];

    final list = jsonDecode(json) as List<dynamic>;
    return list.map((item) {
      final map = item as Map<String, dynamic>;
      return Account(
        id: map['id'] as String,
        username: map['username'] as String,
        sessionCookie: SessionCookie(
          value: map['cookieValue'] as String,
          expiresAt: DateTime.parse(map['cookieExpires'] as String),
          rawCookie: map['cookieRaw'] as String?,
          modhash: map['cookieModhash'] as String?,
        ),
      );
    }).toList();
  }

  Future<void> save(Account account) async {
    final accounts = await loadAll();
    final idIndex = accounts.indexWhere((a) => a.id == account.id);
    if (idIndex >= 0) {
      accounts[idIndex] = account;
      await _persistAll(accounts);
      return;
    }

    final usernameIndex = accounts.indexWhere((a) => a.username == account.username);
    if (usernameIndex >= 0) {
      accounts[usernameIndex] = account;
    } else {
      accounts.add(account);
    }

    await _persistAll(accounts);
  }

  Future<void> clearAllExcept(String accountId) async {
    final accounts = await loadAll();
    final active = accounts.where((a) => a.id == accountId).toList();
    await _persistAll(active);
  }

  Future<void> replaceAll(List<Account> accounts) async {
    await _persistAll(accounts);
  }

  Future<void> remove(String accountId) async {
    final accounts = await loadAll();
    final remaining = accounts.where((a) => a.id != accountId).toList();
    await _persistAll(remaining);

    final activeId = await _storage.read(key: _activeAccountIdKey);
    if (activeId == accountId) {
      await _storage.delete(key: _activeAccountIdKey);
    }
  }

  Future<void> setActive(String accountId) async {
    await _storage.write(key: _activeAccountIdKey, value: accountId);
  }

  Future<Account?> loadActive() async {
    final activeId = await _storage.read(key: _activeAccountIdKey);
    if (activeId == null) return null;
    final all = await loadAll();
    return all.where((a) => a.id == activeId).firstOrNull;
  }

  Future<void> _persistAll(List<Account> accounts) async {
    final json = accounts
        .map((a) => {
              'id': a.id,
              'username': a.username,
              'cookieValue': a.sessionCookie.value,
              'cookieExpires': a.sessionCookie.expiresAt.toIso8601String(),
              if (a.sessionCookie.rawCookie != null)
                'cookieRaw': a.sessionCookie.rawCookie,
              if (a.sessionCookie.modhash != null)
                'cookieModhash': a.sessionCookie.modhash,
            })
        .toList();
    await _storage.write(key: _accountsKey, value: jsonEncode(json));
  }
}
```

Note: methods `loadAll`, `loadActive`, `save`, `setActive`, `clearAllExcept`, `replaceAll`, `remove` now return `Future` since all FlutterSecureStorage reads/writes are async.

- [ ] **Step 5: Update auth_providers.dart for async AccountRepository**

The `accountsProvider` currently calls `loadAll()` synchronously. It needs to become `FutureProvider`:

```dart
final accountsProvider = FutureProvider<List<Account>>((ref) async {
  ref.watch(accountListVersionProvider);
  return ref.watch(accountRepositoryProvider).loadAll();
});
```

And `activeAccountProvider` notifier must handle async:

In `account_notifier.dart`, update `ActiveAccountNotifier` to call `await _repository.loadActive()` in its `init()` method. Add an `init()` call in the constructor.

- [ ] **Step 6: Update main.dart to inject FlutterSecureStorage**

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// ... other imports

final prefs = await SharedPreferences.getInstance();
final secureStorage = const FlutterSecureStorage();

runApp(
  ProviderScope(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      secureStorageProvider.overrideWithValue(secureStorage),
    ],
    child: const FspezApp(),
  ),
);
```

- [ ] **Step 7: Update account_repository_test.dart**

Existing tests use `SharedPreferences` mock; replace with `FakeFlutterSecureStorage` or mock `FlutterSecureStorage`. Use `mocktail`:

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// ... existing test imports

class FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final _store = <String, String>{};
  @override
  Future<void> write({required String key, required String? value}) async {
    _store[key] = value!;
  }
  @override
  Future<String?> read({required String key}) async => _store[key];
  @override
  Future<void> delete({required String key}) async => _store.remove(key);
}
```

- [ ] **Step 8: Run tests**

```bash
cd F:\OpenCode\fspez && flutter test
```

Expected: all tests pass. Fix any compilation issues from async API changes.

- [ ] **Step 9: Commit**

```bash
git add -A && git commit -m "fix: store session cookies in flutter_secure_storage"
```

---

### Task 2: Unify pagination abstractions

**Problem:** Two parallel pagination abstractions — `CursorPaginatedNotifier` (abstract, 9 methods) and `PaginatedNotifier` (concrete). `InboxNotifier` extends `CursorPaginatedNotifier` but never calls `loadInitial()` — it bypasses via constructor microtask + `loadTab()`. The 9-method abstract contract is unnecessary overhead for `InboxNotifier`.

**Solution:** Detach `InboxNotifier` from `CursorPaginatedNotifier`, making it a standalone `StateNotifier<InboxState>`. Then inline `CursorPaginatedNotifier` into `PaginatedNotifier` since it's the only consumer left.

**Files:**
- Modify: `lib/src/data/inbox_notifier.dart` — extend `StateNotifier<InboxState>` directly, inline pagination logic
- Modify: `lib/src/data/cursor_paginated_notifier.dart` — merge into paginated_notifier.dart, then delete
- Modify: `lib/src/data/paginated_notifier.dart` — absorb cursor logic
- Delete: `lib/src/data/cursor_paginated_notifier.dart`
- No change: `lib/src/data/paginated_list_state.dart`

- [ ] **Step 1: Rewrite InboxNotifier to extend StateNotifier directly**

Replace `InboxNotifier` class in `inbox_notifier.dart`:

```dart
class InboxNotifier extends StateNotifier<InboxState> {
  final InboxRepository _repository;
  final Account? _account;
  String? after;
  bool _hasMore = false;

  InboxNotifier(this._repository, this._account, {bool autoLoad = true})
      : super(const InboxState(isLoading: true)) {
    if (autoLoad) {
      Future.microtask(() async {
        await loadTab(InboxTab.all);
        await refreshUnreadCount();
      });
    }
  }

  Future<void> loadInitial() async {
    state = const InboxState(isLoading: true);
    after = null;
    _hasMore = false;
    try {
      final feed = await _fetch(state.tab, after: null);
      after = feed.after;
      _hasMore = feed.hasMorePages;
      state = InboxState(
        tab: state.tab,
        messages: feed.items,
        isLoading: false,
        hasMore: feed.hasMorePages,
        unreadCount: state.tab == InboxTab.unread ? feed.items.length : state.unreadCount,
      );
    } catch (e) {
      state = InboxState(isLoading: false, error: e.toString(), unreadCount: state.unreadCount);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !_hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final feed = await _fetch(state.tab, after: after);
      after = feed.after;
      _hasMore = feed.hasMorePages;
      state = state.copyWith(
        messages: [...state.messages, ...feed.items],
        isLoadingMore: false,
        hasMore: feed.hasMorePages,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<void> refresh() => loadInitial();

  // ... keep loadTab, _fetch, refreshUnreadCount, markAsRead unchanged from current
}
```

- [ ] **Step 2: Run inbox notifier tests**

```bash
cd F:\OpenCode\fspez && flutter test test/data/inbox_notifier_test.dart
```

Expected: all pass. If any reference `CursorPaginatedNotifier` methods, update accordingly.

- [ ] **Step 3: Merge CursorPaginatedNotifier into PaginatedNotifier**

In `cursor_paginated_notifier.dart` move the content into `paginated_notifier.dart`. `PaginatedNotifier` already contains all concrete implementations — only the abstract class definition needs moving. After:

In `paginated_notifier.dart`:

```dart
import 'paginated_list_state.dart';

class PaginatedResult<T> {
  final List<T> items;
  final String? after;
  final bool hasMore;
  const PaginatedResult({required this.items, this.after, this.hasMore = false});
}

class PaginatedNotifier<T> extends StateNotifier<PaginatedListState<T>> {
  final Future<PaginatedResult<T>> Function({String? after}) _fetchPage;
  String? after;
  bool _hasMore = false;

  PaginatedNotifier({
    required Future<PaginatedResult<T>> Function({String? after}) fetchPage,
    bool autoLoad = true,
  })  : _fetchPage = fetchPage,
        super(const PaginatedListState.initial()) {
    if (autoLoad) {
      Future.microtask(() => loadInitial());
    }
  }

  Future<void> loadInitial() async {
    state = const PaginatedListState(isLoading: true);
    after = null;
    _hasMore = false;
    try {
      final page = await _fetchPage(after: null);
      after = page.after;
      _hasMore = page.hasMore;
      state = PaginatedListState<T>(
        items: page.items,
        isLoading: false,
        hasMore: page.hasMore,
        isStale: false,
      );
    } catch (e) {
      state = PaginatedListState<T>(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !_hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await _fetchPage(after: after);
      after = page.after;
      _hasMore = page.hasMore;
      state = PaginatedListState<T>(
        items: [...state.items, ...page.items],
        isLoading: false,
        hasMore: page.hasMore,
        isStale: state.isStale,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<void> refresh() => loadInitial();

  void removeItem(bool Function(T) predicate) {
    state = state.removeItem(predicate);
  }
}
```

- [ ] **Step 4: Delete cursor_paginated_notifier.dart**

```bash
Remove-Item F:\OpenCode\fspez\lib\src\data\cursor_paginated_notifier.dart
```

- [ ] **Step 5: Update all imports**

Run grep to find any remaining imports of `cursor_paginated_notifier.dart` and update them to `paginated_notifier.dart`:

```bash
cd F:\OpenCode\fspez && Select-String -Pattern "cursor_paginated_notifier" -Recurse -Path "lib/**/*.dart"
```

If any found, update those imports.

- [ ] **Step 6: Run all tests**

```bash
cd F:\OpenCode\fspez && flutter test
```

Expected: all pass.

- [ ] **Step 7: Commit**

```bash
git add -A && git commit -m "refactor: unify pagination abstractions, detach InboxNotifier from CursorPaginatedNotifier"
```

---

### Task 3: Deduplicate HTTP transport headers

**Problem:** `HttpTransport._headersFor()` has 6 switch cases. Cases `oldReddit`, `comment`, `submit`, `compose` are nearly identical, differing only by charset in Content-Type and User-Agent. ~40 lines of duplicated header maps.

**Solution:** Extract shared `_formHeaders` helper. `json` and `form` cases are trivially different and can stay explicit.

**Files:**
- Modify: `lib/src/data/http_transport.dart:82-133`

- [ ] **Step 1: In http_transport.dart, add a shared helper method**

Insert after `_headersForHtml`:

```dart
Map<String, String> _formHeaders(SessionCookie? cookie, {bool useBrowserUA = false}) {
  final c = cookie?.rawCookie ?? 'reddit_session=${cookie?.value ?? ''}';
  return {
    'User-Agent': useBrowserUA ? _browserUA : 'fspez/0.1.0',
    'Content-Type': 'application/x-www-form-urlencoded${useBrowserUA ? '; charset=UTF-8' : ''}',
    'Cookie': c,
    if (useBrowserUA) 'Accept': '*/*',
    if (useBrowserUA) 'X-Requested-With': 'XMLHttpRequest',
    if (cookie?.modhash != null) 'X-Modhash': cookie!.modhash!,
  };
}
```

- [ ] **Step 2: Refactor the duplicate cases in _headersFor**

Replace the body of `_headersFor`:

```dart
Map<String, String> _headersFor(ApiEndpoint kind, SessionCookie? cookie) {
  switch (kind) {
    case ApiEndpoint.json:
      return {
        'User-Agent': 'fspez/0.1.0',
        'Content-Type': 'application/json',
        if (cookie != null) 'Cookie': 'reddit_session=${cookie.value}',
      };
    case ApiEndpoint.form:
      return {
        'User-Agent': 'fspez/0.1.0',
        'Content-Type': 'application/x-www-form-urlencoded',
        if (cookie != null) 'Cookie': 'reddit_session=${cookie.value}',
      };
    case ApiEndpoint.oldReddit:
    case ApiEndpoint.submit:
      return _formHeaders(cookie, useBrowserUA: true);
    case ApiEndpoint.comment:
    case ApiEndpoint.compose:
      return _formHeaders(cookie, useBrowserUA: false);
  }
}
```

- [ ] **Step 3: Run tests**

```bash
cd F:\OpenCode\fspez && flutter test
```

Expected: all pass (no behavior change).

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "refactor: deduplicate HTTP transport headers"
```

---

### Task 4: Split api_responses.dart into per-entity files

**Problem:** `lib/src/data/api_responses.dart` is 541 lines handling parsing + domain mapping for posts, comments, messages, subreddits, rules, and search users. Single file, single responsibility violated.

**Solution:** Split into one file per API response class.

**Files:**
- Create: `lib/src/data/api_responses/api_post.dart`
- Create: `lib/src/data/api_responses/api_comment.dart`
- Create: `lib/src/data/api_responses/api_message.dart`
- Create: `lib/src/data/api_responses/api_subreddit.dart`
- Create: `lib/src/data/api_responses/api_listing.dart`
- Create: `lib/src/data/api_responses/api_search_user.dart`
- Create: `lib/src/data/api_responses/api_subreddit_rule.dart`
- Create: `lib/src/data/api_responses/api_subreddit_rules.dart`
- Delete: `lib/src/data/api_responses.dart`
- Modify: All files that import `api_responses.dart`

- [ ] **Step 1: Create the directory**

```bash
New-Item -ItemType Directory -Path F:\OpenCode\fspez\lib\src\data\api_responses -Force
```

- [ ] **Step 2: Find all files importing api_responses.dart**

```bash
cd F:\OpenCode\fspez && Select-String -Pattern "import.*api_responses" -Recurse -Path "lib/**/*.dart"
```

Expected results: `feed_parser.dart`, `comment_parser.dart`, `inbox_parser.dart`, `comment_providers.dart`, etc.

- [ ] **Step 3: Extract ApiListing into api_listing.dart**

```dart
// lib/src/data/api_responses/api_listing.dart
import 'api_post.dart';

class ApiListing {
  final String? after;
  final String? before;
  final List<ApiPost> children;

  ApiListing({this.after, this.before, required this.children});

  factory ApiListing.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final children = (data['children'] as List<dynamic>)
        .map((c) => ApiPost.fromJson(c['data'] as Map<String, dynamic>))
        .toList();
    return ApiListing(
      after: data['after'] as String?,
      before: data['before'] as String?,
      children: children,
    );
  }

  factory ApiListing.fromListing(Map<String, dynamic> json) {
    return ApiListing.fromJson(json);
  }
}
```

- [ ] **Step 4: Extract ApiPost into api_post.dart**

Copy the `ApiPost` class (lines 33-190 from current api_responses.dart) into `api_responses/api_post.dart`. Update import to use `'../post_mapping.dart'` and `'../parsers/shared_parsers.dart'`.

- [ ] **Step 5: Extract ApiComment into api_comment.dart**

Copy the `ApiComment` class (lines 232-324 from current) into `api_responses/api_comment.dart`.

- [ ] **Step 6: Extract ApiMessage into api_message.dart**

Copy the `ApiMessage` class (lines 327-397 from current) into `api_responses/api_message.dart`.

- [ ] **Step 7: Extract ApiSubreddit, ApiSubredditRules, ApiSubredditRule into separate files**

`ApiSubreddit` (lines 400-486) → `api_responses/api_subreddit.dart`
`ApiSubredditRules` (lines 488-505) + `ApiSubredditRule` (lines 507-540) → `api_responses/api_subreddit_rule.dart` and `api_responses/api_subreddit_rules.dart`

- [ ] **Step 8: Extract ApiSearchUser into api_search_user.dart**

Copy lines 192-230 into `api_responses/api_search_user.dart`.

- [ ] **Step 9: Create barrel export and update imports**

Create `api_responses/api_responses.dart` as barrel:

```dart
export 'api_listing.dart';
export 'api_post.dart';
export 'api_comment.dart';
export 'api_message.dart';
export 'api_subreddit.dart';
export 'api_subreddit_rule.dart';
export 'api_subreddit_rules.dart';
export 'api_search_user.dart';
```

Update existing importers: change `import 'api_responses.dart'` → `import 'api_responses/api_responses.dart'`.

- [ ] **Step 10: Delete the old api_responses.dart**

```bash
Remove-Item F:\OpenCode\fspez\lib\src\data\api_responses.dart
```

- [ ] **Step 11: Run tests**

```bash
cd F:\OpenCode\fspez && flutter test
```

Expected: all pass (pure mechanical refactor, no behavior change).

- [ ] **Step 12: Commit**

```bash
git add -A && git commit -m "refactor: split api_responses.dart into per-entity files"
```

---

### Task 5: Extract _PostMediaTile from post_detail_screen.dart

**Problem:** `post_detail_screen.dart` is 805 lines. `_PostMediaTile` is 200 lines embedded as a private widget.

**Solution:** Extract into its own file in `presentation/widgets/`. Make it public if referenced from tests or other screens; if not, keep it as a library-private widget in a focused file.

**Files:**
- Create: `lib/src/presentation/widgets/post_media_tile.dart`
- Modify: `lib/src/presentation/screens/post_detail_screen.dart` — remove _PostMediaTile, _PostMediaTileState, import new file

- [ ] **Step 1: Check for other references to _PostMediaTile**

```bash
cd F:\OpenCode\fspez && Select-String -Pattern "_PostMediaTile" -Recurse -Path "lib/**/*.dart" -SimpleMatch
```

Expected: only `post_detail_screen.dart`. If so, the widget is a private class used only in that file. Extract with `@visibleForTesting` if needed, or keep package-private.

- [ ] **Step 2: Create post_media_tile.dart**

Copy the `_PostMediaTile` and `_PostMediaTileState` classes (lines 426-646) into `lib/src/presentation/widgets/post_media_tile.dart`:

```dart
import 'package:flutter/material.dart';

class PostMediaTile extends StatefulWidget {
  final String imageUrl;
  final VoidCallback onTap;
  final String? badgeText;
  final bool isVideo;

  const PostMediaTile({
    super.key,
    required this.imageUrl,
    required this.onTap,
    this.badgeText,
    this.isVideo = false,
  });

  @override
  State<PostMediaTile> createState() => _PostMediaTileState();
}

// ... rest of the state class (rename _PostMediaTileState to PostMediaTileState or keep private)
```

- [ ] **Step 3: Update the reference in post_detail_screen.dart**

Replace all `_PostMediaTile(` with `PostMediaTile(` in the file. Add the import.

- [ ] **Step 4: Run tests**

```bash
cd F:\OpenCode\fspez && flutter test
```

Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "refactor: extract PostMediaTile widget from post_detail_screen"
```

---

### Task 6: Remove unused codegen dependencies

**Problem:** `freezed_annotation` and `json_annotation` are runtime deps; `freezed`, `json_serializable`, `build_runner` are dev deps — but no code generation is used. Models are hand-written with `EquatableMixin` + manual `copyWith`.

**Solution:** Remove all five unused dependencies.

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Remove entries from pubspec.yaml**

Under `dependencies:`, remove:
- `freezed_annotation: ^2.4.0`
- `json_annotation: ^4.9.0`

Under `dev_dependencies:`, remove:
- `build_runner: ^2.4.0`
- `freezed: ^2.5.0`
- `json_serializable: ^6.8.0`

- [ ] **Step 2: Verify no imports reference removed packages**

```bash
cd F:\OpenCode\fspez && Select-String -Pattern "^import.*(freezed|json_annotation|json_serializable|build_runner)" -Recurse -Path "lib/**/*.dart" "test/**/*.dart"
```

Expected: no matches.

- [ ] **Step 3: Run flutter pub get and tests**

```bash
cd F:\OpenCode\fspez && flutter pub get && flutter test
```

Expected: all pass.

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "chore: remove unused freezed/json_serializable deps"
```

---

### Task 7: Fix silent catch blocks

**Problem:** Three locations swallow exceptions silently, losing diagnostic information.

**Files:**
- Modify: `lib/src/data/vote_notifier.dart:19`
- Modify: `lib/src/data/inbox_notifier.dart:109-111`
- Modify: `lib/src/data/session_health.dart:112`

- [ ] **Step 1: Add logging to vote_notifier.dart**

Replace:

```dart
} catch (_) {}
```

With:

```dart
} catch (e) {
  debugPrint('VoteNotifier.vote failed: $e');
}
```

- [ ] **Step 2: Add logging to inbox_notifier.dart**

Replace:

```dart
} catch (_) {
  // Keep the last known badge count; inbox loading errors are shown in-tab.
}
```

With:

```dart
} catch (e) {
  debugPrint('InboxNotifier.refreshUnreadCount failed: $e');
  // Keep the last known badge count; inbox loading errors are shown in-tab.
}
```

- [ ] **Step 3: Add logging to session_health.dart**

Replace:

```dart
} catch (_) {
  return SessionHealth.unknown;
}
```

With:

```dart
} catch (e) {
  debugPrint('SessionHealth check failed: $e');
  return SessionHealth.unknown;
}
```

- [ ] **Step 4: Run tests**

```bash
cd F:\OpenCode\fspez && flutter test
```

Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "fix: add debug logging to silent catch blocks"
```

---

### Task 8: PostActionsService hardening

**Problem:** `PostActionsService` holds `SessionCookie?` as nullable and checks at each method — silently no-ops when null. The `edit` method returns `Future<bool>` with `false` meaning "no session" — this is silently ignored by call sites.

**Solution:** Make `SessionCookie` required at construction time (fail fast). Simplify `edit` signature to `Future<void>`.

**Files:**
- Modify: `lib/src/data/post_actions_service.dart`
- Modify: `lib/src/data/write_providers.dart` — update provider to provide non-null cookie

- [ ] **Step 1: Make sessionCookie required in PostActionsService**

```dart
class PostActionsService {
  final VoteNotifier _voteNotifier;
  final SaveNotifier _saveNotifier;
  final HideNotifier _hideNotifier;
  final DeleteNotifier _deleteNotifier;
  final EditNotifier _editNotifier;
  final SessionCookie _sessionCookie;

  const PostActionsService({
    required VoteNotifier voteNotifier,
    required SaveNotifier saveNotifier,
    required HideNotifier hideNotifier,
    required DeleteNotifier deleteNotifier,
    required EditNotifier editNotifier,
    required SessionCookie sessionCookie,  // non-nullable now
  })  : _voteNotifier = voteNotifier,
      // ...
```

- [ ] **Step 2: Simplify method signatures**

Remove null checks:

```dart
Future<void> delete(String fullname) {
  return _deleteNotifier.delete(fullname, _sessionCookie);
}

Future<void> edit(String thingId, String text) {
  return _editNotifier.edit(thingId, text, _sessionCookie);
}
```

- [ ] **Step 3: Update write_providers.dart**

The provider that constructs `PostActionsService` should guard on null account (return `null` or a dummy if no active account). If there's no active account, the service shouldn't be used at all:

```dart
final postActionsServiceProvider = Provider<PostActionsService?>((ref) {
  final account = ref.watch(activeAccountProvider);
  final cookie = account?.sessionCookie;
  if (cookie == null) return null;
  return PostActionsService(
    voteNotifier: ref.watch(voteProvider.notifier),
    saveNotifier: ref.watch(saveProvider.notifier),
    // ... etc, pass cookie
  );
});
```

- [ ] **Step 4: Update call sites that use postActionsServiceProvider**

Current callers like `PostDetailScreen` call `ref.read(postActionsServiceProvider)` — they need to handle null:

```dart
final service = ref.read(postActionsServiceProvider);
if (service == null) return;
```

Or add a dummy/null-object pattern if callers prefer.

- [ ] **Step 5: Update tests**

```dart
// post_actions_service_test.dart — update test setup to provide non-null cookie
```

- [ ] **Step 6: Run tests**

```bash
cd F:\OpenCode\fspez && flutter test
```

Expected: all pass.

- [ ] **Step 7: Commit**

```bash
git add -A && git commit -m "refactor: make SessionCookie required in PostActionsService"
```

---

### Task 9: Minor polish

**Problem:** Two small issues from review: `FeedPageNotifier.autoLoad` semantic coupling and OpenUrl platform conditional complexity.

**Files:**
- Modify: `lib/src/data/feed_providers.dart` — add doc comment
- Modify: `lib/src/presentation/utils/open_url.dart` — already a conditional export, leave as-is
- Modify: `lib/src/presentation/utils/open_url_real.dart` and `open_url_stub.dart` — rename to match conventions

- [ ] **Step 1: Document the autoLoad-cache coupling**

In `feed_providers.dart`, add a comment above the `FeedPageNotifier` construction explaining the cache/autoLoad interaction:

```dart
// If we have cached data, seed the notifier with it and trigger a background
// refresh. This avoids showing a loading spinner on repeat visits. The
// notifier's autoLoad is set to false so it doesn't double-fetch — cached
// content renders immediately; refresh() handles the network update.
final notifier = FeedPageNotifier(
  fetchPage: ({after}) async { /* ... */ },
  autoLoad: cachedFeed == null,
);
```

- [ ] **Step 2: Check if OpenUrl simplification is worth it**

The current pattern uses Dart conditional exports — a standard pattern for platform-specific code. This is fine. No change needed. The review noted it as optional.

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "docs: document FeedPageNotifier autoLoad-cache coupling"
```

---

## Self-Review

**1. Spec coverage:**
- ✅ Secure cookie storage — Task 1
- ✅ Pagination unification — Task 2
- ✅ HTTP header dedup — Task 3
- ✅ Split api_responses.dart — Task 4
- ✅ Extract PostMediaTile — Task 5
- ✅ Remove unused deps — Task 6
- ✅ Silent catch blocks — Task 7
- ✅ PostActionsService hardening — Task 8
- ✅ Minor polish — Task 9

**2. Placeholder scan:** No "TBD", "TODO", "implement later", "fill in details", or "add appropriate error handling".

**3. Type consistency:** All method signatures reference actual types in the codebase. No cross-task reference mismatch.

**Plan gaps identified:** None — all review findings are covered by at least one task.
