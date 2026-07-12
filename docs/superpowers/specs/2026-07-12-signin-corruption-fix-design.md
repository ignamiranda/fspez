# Fix Sign-In Crash on Corrupted Secure Storage (Issue #24)

## Problem

`PlatformException(BadPaddingException)` thrown by `FlutterSecureStorage.read()` on Android when the OS keystore entry for the app's encrypted data has become invalid. No try/catch exists anywhere in the storage layer, so the exception propagates unhandled through `ActiveAccountNotifier._init()` → `_AppGate` renders `LoginScreen` with no error feedback to the user.

## Design

### 1. AccountRepository — error-tolerant storage reads

Wrap all `FlutterSecureStorage.read()` calls in try/catch for `PlatformException`. On read failure, delete the corrupted key and return `null` / empty list. Write failures (`_storage.write()`) propagate to the caller.

Methods affected:
- `loadAll()` — catch read failure, delete corrupted `_accountsKey`, return `[]`
- `loadActive()` — catch read failure, return `null`
- `remove()` — catch read failure on active ID lookup, treat as null; `delete()` failures propagate

### 2. ActiveAccountNotifier._init() — startup error boundary

Wrap `_init()` body in try/catch. On failure: state stays `null`, user sees login screen. Log the error via `debugPrint`.

Set a flag or expose an error state so the UI layer can notify the user.

### 3. _AppGate — user-facing error feedback

Add a `corruptedSessionProvider` (simple `StateProvider<bool>`) that `_init()` sets to `true` on corruption. `_AppGate` shows a snackbar when this is true: "Saved session data was corrupted. Please sign in again." Reset to `false` when dismissed.

## Files Changed

| File | Change |
|------|--------|
| `lib/src/data/account_repository.dart` | try/catch on `_storage.read()` in `loadAll()`, `loadActive()`, `remove()` |
| `lib/src/data/account_notifier.dart` | try/catch in `_init()`, set corrupted state provider |
| `lib/src/data/auth_providers.dart` | add `corruptedSessionProvider` |
| `lib/src/presentation/app.dart` | listen to corrupted session provider, show snackbar |

## Non-goals

- No per-account key isolation (that's Approach B)
- No `deleteAll()` on corruption (that's Approach C)
- No changes to the login flow, session health, or feed
