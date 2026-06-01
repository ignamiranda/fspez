# Handoff: Custom home feed tabs

## Approved mobile personalization feature

Add **custom home feed tabs** so users can pin and reorder a small set of frequently used feeds at the top of the main feed.

## Current goal

Implement features to reach feature parity with the official Reddit mobile app, prioritizing mobile-app parity, mobile-quality UX, architecture, reliability, and overall app quality.

## Why this feature

Mobile users often rotate between Home, Popular, All, favorite subreddits, Saved, History, and repeated searches. Custom feed tabs give fast access to high-value destinations without overloading bottom navigation.

## Existing related implementation

Inspect these areas first:

- `lib/src/presentation/screens/feed_screen.dart`
  - Main feed sort/source selection and refresh behavior.
- `lib/src/presentation/widgets/feed_screen_scaffold.dart`
  - Shared feed rendering.
- `lib/src/presentation/screens/subreddit_feed_screen.dart`
  - Existing subreddit feed display/navigation target.
- `lib/src/presentation/screens/account_screen.dart`
  - Saved/hidden/history entry points.
- `lib/src/presentation/screens/search_screen.dart`
  - Search entry and query patterns.
- `lib/main.dart`
  - `SharedPreferences` initialization/override pattern.

Related approved handoffs:

- `handoffs/2026-05-27-joined-communities-management-handoff.md`
- `handoffs/2026-05-27-feed-density-modes-handoff.md`
- `handoffs/2026-05-27-in-app-settings-screen-handoff.md`
- `handoffs/2026-05-27-recently-visited-communities-users-handoff.md`

## Suggested implementation scope

Smallest useful vertical slice:

1. Add a persisted list of pinned feed tabs.
2. Support built-in tab types first:
   - Home.
   - Popular.
   - All, if already supported.
3. Add subreddit tabs once subreddit feed loading can be reused cleanly.
4. Show tabs at the top of the main feed with mobile-friendly horizontal scrolling.
5. Let users add/remove/reorder tabs through a simple management sheet/screen.
6. Keep bottom navigation unchanged.

## UX requirements

- Default tabs should preserve current behavior for existing users.
- Tabs must be thumb-friendly and not consume too much vertical space.
- Reordering should be simple; drag-and-drop is nice but up/down controls are acceptable for the first slice.
- Avoid duplicating full subreddit navigation if a tab can reuse the existing feed scaffold.
- Empty/misconfigured tab state should recover gracefully.

## Technical discovery needed

Before editing, inspect:

- Whether `FeedScreen` already has a source enum/model that can represent Home/Popular/All/subreddit.
- Whether subreddit feeds can be rendered inside the main feed tab area without duplicating `SubredditFeedScreen` header behavior.
- Existing saved/history screens and whether they should be true tabs or remain account destinations.
- Existing settings persistence/provider pattern if implemented.
- How account switching should affect pinned tabs.

## Deferred out of scope

- Reddit custom feeds/multireddits unless endpoint support is separately implemented.
- Complex recommendations for tabs.
- Per-tab sort persistence beyond current feed sort behavior unless straightforward.
- Tablet-specific navigation redesign.

## Acceptance criteria

- Main feed can show at least Home/Popular/All-style pinned tabs where supported.
- User can add/remove/reorder tabs and choices persist across restarts.
- Selecting a tab loads the correct feed without breaking refresh/pagination.
- Existing bottom navigation remains simple and unchanged.
- Existing feed behavior remains the default if the user never customizes tabs.

## Validation

Run after implementation:

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test` if tests are added/changed.
- Manual `flutter run` checks:
  - Open main feed and switch between pinned tabs.
  - Add/remove/reorder tabs and restart app.
  - Confirm selected tabs load, refresh, and paginate correctly.
  - Confirm bottom navigation still works as before.

## Suggested agents

- Use `@designer` for mobile tab layout and management UI polish.
- Reuse explorer session `exp-2 Check post edit implementation` for feed/subreddit context if needed.
- Use `@fixer` for bounded implementation after feed source model and persistence shape are clear.
