# Handoff: Optimistic action undo snackbars

## Approved mobile trust/reliability improvement

Add **optimistic action feedback with undo snackbars** for reversible Reddit actions.

## Current goal

Implement features to reach feature parity with the official Reddit mobile app, prioritizing mobile-app parity and mobile-quality UX.

## Why this improvement

Mobile users tap quickly and sometimes accidentally. Actions like hide, save, unsubscribe, mute, block, and delete should feel immediate but recoverable where Reddit/API semantics allow it. Undo snackbars reduce anxiety, make optimistic updates safer, and pair well with mobile bottom-sheet action menus.

## Existing related implementation

Inspect these areas first:

- `lib/src/data/optimistic_state_notifier.dart`
  - Existing optimistic update abstraction.
- `lib/src/data/write_operation_notifier.dart`
  - Existing write operation loading/error pattern.
- `lib/src/data/vote_notifier.dart`
  - Vote optimistic behavior; project notes say vote keeps optimistic state on error.
- `lib/src/data/save_notifier.dart`
  - Save optimistic behavior; project notes say save reverts and rethrows on error.
- `lib/src/data/hide_notifier.dart`
  - Hide optimistic behavior; project notes say hide reverts and rethrows on error.
- `lib/src/presentation/widgets/post_card.dart`
  - Current post actions.
- `lib/src/presentation/widgets/feed_screen_scaffold.dart`
  - Feed-level save/hide/delete callback wiring.
- `lib/src/presentation/screens/subreddit_feed_screen.dart`
  - Subscribe/unsubscribe flows.
- `lib/src/presentation/screens/post_detail_screen.dart`
  - Detail actions and comment actions.

Related approved handoffs:

- `handoffs/2026-05-27-bottom-sheet-action-menus-handoff.md`
- `handoffs/2026-05-27-centralize-thing-actions-handoff.md`
- `handoffs/2026-05-27-community-mute-unmute-handoff.md`
- `handoffs/2026-05-27-block-unblock-users-handoff.md`

## Suggested implementation scope

Smallest useful vertical slice:

1. Add undo snackbar behavior for hide/unhide or save/unsave first.
2. Action applies immediately in UI.
3. Snackbar shows a concise message and “Undo”.
4. If Undo is tapped, call the inverse Reddit action and restore local UI state.
5. If the original action fails, preserve existing failure semantics and show an error.
6. Expand to other reversible actions after the first path is stable.

Good first candidates:

- Hide post → remove immediately from feed → snackbar “Post hidden” + Undo.
- Save/unsave → toggle immediately → snackbar “Post saved” / “Removed from saved” + Undo.
- Unsubscribe → update subreddit header/list → snackbar “Left r/name” + Undo.

Use caution with destructive actions:

- Delete may not be cleanly reversible via Reddit API. Keep confirmation-first and do not promise undo unless actual restoration is possible.
- Block/mute may be reversible but can have wider side effects; consider separate confirmation plus undo only after endpoint behavior is verified.

## UX requirements

- Snackbar copy should be short and specific.
- Undo window should be long enough for mobile users to notice but not intrusive.
- Avoid stacking many snackbars confusingly; replace or queue intentionally.
- Do not show Undo for actions that cannot actually be undone.
- If Undo fails, show a clear failure message and keep UI consistent with server/local state.

## Architecture guidance

- Keep snackbar presentation in UI layer.
- Keep inverse action logic in notifiers/services, especially if `centralize-thing-actions-handoff` is implemented first.
- Avoid duplicating inverse action logic across every screen.
- Tests should cover action → undo → restored state where possible.

## Technical discovery needed

Before editing, inspect:

- Current snackbar/scaffold messenger usage.
- Whether feed removal for hide is local-only or provider-level.
- Whether saved/hidden/history screens need immediate consistency after undo.
- Which inverse Reddit APIs already exist in `RedditClient`.
- Whether action notifiers expose enough state to restore previous values.

## Deferred out of scope

- Offline undo queue.
- Undo for irreversible deletes unless Reddit supports restoration.
- Global action history timeline.
- Complex multi-action batch undo.

## Acceptance criteria

- At least one high-value reversible action has optimistic feedback plus working Undo.
- Undo calls the correct inverse API and restores UI state.
- Original failure behavior remains correct.
- No Undo is offered for irreversible actions.
- Implementation can be reused for additional reversible actions.

## Validation

Run after implementation:

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test` if tests are added/changed.
- Manual `flutter run` checks with an authenticated account:
  - Perform the first supported action and confirm immediate UI feedback.
  - Tap Undo and confirm state restores.
  - Let snackbar expire and confirm final state remains.
  - Test error handling if practical.

## Suggested skills / agents

- Use `@designer` for mobile snackbar timing/copy/interaction polish.
- Reuse explorer session `exp-2 Check post edit implementation` for current action wiring if needed.
- Use `@fixer` for bounded implementation after the first reversible action is chosen.
- Use `@oracle` only if action-service centralization and undo semantics need architecture review.
