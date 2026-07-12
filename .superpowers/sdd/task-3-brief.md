### Task 3: _AppGate — user-facing error feedback

**Files:**
- Modify: `lib/src/presentation/app.dart` — listen to `corruptedSessionProvider`, show snackbar

**Interfaces:**
- Consumes: `corruptedSessionProvider` from `auth_providers.dart` (already exists from Task 2)

- [ ] **Step 1: Add snackbar listener for corrupted session**

In `_AppGateState.build()`, before the existing `ref.listen(sessionHealthProvider, ...)`:

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

The import `import '../data/auth_providers.dart';` is already at line 11 of `app.dart`.

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
