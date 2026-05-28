# Handoff: Pull-to-refresh polish with feedback

## Approved mobile feed delight improvement

Improve **pull-to-refresh polish** for mobile feed browsing with clearer refresh states, status feedback, optional haptics, and smart scroll behavior.

## Current goal

Implement features to reach feature parity with the official Reddit mobile app, prioritizing mobile-app parity, mobile-quality UX, architecture, reliability, and overall app quality.

## Why this improvement

Refresh is a core Reddit mobile interaction. A native-feeling pull-to-refresh makes feeds feel alive and trustworthy: users should know when content is refreshing, when new posts arrived, and when nothing changed, without losing their place unexpectedly.

## Existing related implementation

Inspect these areas first:

- `lib/src/presentation/screens/feed_screen.dart`
  - Main feed sort/refresh behavior.
- `lib/src/presentation/widgets/feed_screen_scaffold.dart`
  - Feed list rendering, scroll handling, loading indicators.
- `lib/src/presentation/screens/subreddit_feed_screen.dart`
  - Subreddit feed refresh behavior.
- `lib/src/presentation/screens/search_screen.dart`
  - Search result refresh/list behavior if applicable.
- `lib/src/data/feed_pagination.dart`
  - Existing cursor pagination and refresh state.
- `lib/src/data/inbox_notifier.dart`
  - Existing refresh pattern for another list surface.

Related approved handoffs:

- `handoffs/2026-05-27-standardize-paginated-list-state-handoff.md`
- `handoffs/2026-05-27-offline-cache-stale-while-revalidate-handoff.md`
- `handoffs/2026-05-27-feed-density-modes-handoff.md`

## Suggested implementation scope

Smallest useful vertical slice:

1. Audit current pull-to-refresh behavior on feed and subreddit feed.
2. Ensure refresh is gesture-accessible with a mobile-friendly indicator.
3. Preserve scroll position intelligently when refreshed content overlaps existing content.
4. Show concise feedback after refresh:
   - “New posts loaded” when fresh items appear.
   - “You’re up to date” when no new items appear.
   - “Could not refresh” on failure while keeping existing content visible.
5. Add haptic feedback only if platform support is safe and no-op/fallback behavior is acceptable.
6. Apply the pattern consistently to main feed and subreddit feed first.

## UX requirements

- Pull gesture should feel responsive and not fight normal scrolling.
- Refresh should not blank an already populated feed.
- Users should not lose their reading position unnecessarily.
- Feedback should be brief and non-intrusive.
- Haptics must be optional/platform-safe; do not crash or log noisy errors on unsupported targets.
- Loading, refreshing, and paginating states should be visually distinct.

## Technical discovery needed

Before editing, inspect:

- Whether `RefreshIndicator` is already used.
- Whether feed refresh replaces the whole list or merges new posts.
- Current post identity field available for detecting new items.
- Existing snackbar/toast/status feedback patterns.
- Whether Flutter `HapticFeedback` is suitable for the app’s target platforms.
- Whether scroll controllers are already owned by feed widgets.

## Architecture guidance

- Keep refresh result semantics in the notifier/repository layer where practical: refreshed count, unchanged, failure.
- Keep haptics/status presentation in UI layer.
- Coordinate with standardized pagination state if that architecture handoff is implemented first.
- Avoid large feed rewrites just for polish.

## Deferred out of scope

- Background push updates.
- Full offline sync; covered by stale-while-revalidate handoff.
- Infinite feed recommendation changes.
- Complex animated diffing unless straightforward.

## Acceptance criteria

- Main feed and subreddit feed have polished pull-to-refresh behavior.
- Existing content remains visible during refresh and on refresh failure.
- Refresh completion communicates whether new content arrived.
- Scroll position handling avoids jarring jumps in common cases.
- Optional haptics are guarded by platform-safe usage.

## Validation

Run after implementation:

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test` if tests are added/changed.
- Manual `flutter run` checks:
  - Pull to refresh main feed and subreddit feed.
  - Confirm loading/refresh indicator appears.
  - Confirm success/no-new-content/error feedback.
  - Confirm existing feed content is not blanked on failure.
  - Confirm scroll position behavior feels stable.

## Suggested skills / agents

- Use `@designer` for mobile refresh indicator/status feedback polish.
- Reuse explorer session `exp-2 Check post edit implementation` for feed/subreddit context if needed.
- Use `@fixer` for bounded implementation after refresh semantics are understood.
