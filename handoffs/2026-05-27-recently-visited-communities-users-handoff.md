# Handoff: Recently visited communities and users

## Approved mobile navigation feature

Add a local **Recently visited** surface for communities, users, and optionally posts.

## Current goal

Implement features to reach feature parity with the official Reddit mobile app, prioritizing mobile-app parity, mobile-quality UX, architecture, reliability, and overall app quality.

## Why this feature

Reddit mobile browsing is exploratory. Users jump between subreddits, profiles, posts, search results, and inbox contexts. A lightweight recent-items surface helps users return to places they just visited without relying on search, bookmarks, or full Reddit history.

## Existing related implementation

Inspect these areas first:

- `lib/src/presentation/screens/account_screen.dart`
  - Existing saved/hidden/history entry points; possible place for a “Recent” entry.
- `lib/src/presentation/screens/subreddit_feed_screen.dart`
  - Record community visits when opened.
- `lib/src/presentation/screens/user_profile_screen.dart`
  - Record profile visits when opened.
- `lib/src/presentation/screens/post_detail_screen.dart`
  - Optional post visits if not duplicating existing history behavior.
- `lib/src/presentation/screens/search_screen.dart`
  - Search results navigation into communities/users/posts.
- `lib/main.dart`
  - `SharedPreferences` initialization/override pattern.

Related approved handoffs:

- `handoffs/2026-05-27-read-posts-history-sync-handoff.md`
- `handoffs/2026-05-27-joined-communities-management-handoff.md`
- `handoffs/2026-05-27-in-app-settings-screen-handoff.md`
- `handoffs/2026-05-27-first-run-account-feed-setup-handoff.md`

## Suggested implementation scope

Smallest useful vertical slice:

1. Add a local recent-items store.
2. Record subreddit visits and user profile visits.
3. Add an Account screen entry or lightweight tab/section for “Recently visited”.
4. Display recent communities and users with clear type labels/icons.
5. Tapping an item navigates to the existing subreddit/profile screen.
6. Add “Clear recent” with confirmation.
7. Keep a bounded list, e.g. last 25–50 items, deduplicated by type + identifier.

## Data model guidance

Suggested fields:

- `type`: subreddit, user, optionally post.
- `id` / canonical name: subreddit display name or username.
- `displayTitle`.
- `subtitle` if known.
- `visitedAt` timestamp.
- Optional avatar/icon URL if already available.

## UX requirements

- Recent items should be local-only and privacy-aware.
- Clear action should require confirmation.
- Do not mix recent posts with Reddit account history unless labels are clear.
- Deduplicate repeat visits by moving the item to the top.
- Hide the surface or show a helpful empty state when no recent items exist.
- Keep navigation fast and simple; no new detail screens if existing screens work.

## Technical discovery needed

Before editing, inspect:

- Existing history screen/data implementation to avoid duplicating post history.
- Current route/navigation patterns for subreddit and user profile screens.
- Whether account identity should be part of the key.
  - Recommended: keep recent items per account when authenticated; use a separate logged-out bucket.
- Whether `SharedPreferences` can store a small JSON array cleanly.
- Existing date formatting helpers.

## Architecture guidance

- Keep recent tracking in a small provider/service rather than sprinkling persistence code through screens.
- Screens should call `recordSubredditVisit(...)` / `recordUserVisit(...)` and not know storage details.
- Avoid network fetches for this first slice; use metadata already available at navigation time.

## Deferred out of scope

- Cloud sync of recent visits.
- Full browsing analytics.
- Recommendations based on recent visits.
- Complex grouping by day/week.
- Post read-state/history sync; covered by separate handoff.

## Acceptance criteria

- Visiting a subreddit records it in recents.
- Visiting a user profile records it in recents.
- Recent list persists across app restarts.
- Repeat visits deduplicate and move item to top.
- Clear recents works after confirmation.
- Tapping recent items opens existing screens.

## Validation

Run after implementation:

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test` if tests are added/changed.
- Manual `flutter run` checks:
  - Visit several subreddits and users.
  - Open Account → Recently visited and confirm items appear in order.
  - Revisit one item and confirm it moves to top without duplication.
  - Restart app and confirm recents persist.
  - Clear recents and confirm empty state.

## Suggested agents

- Reuse explorer session `exp-2 Check post edit implementation` for navigation/account/profile context if needed.
- Use `@fixer` for bounded implementation after storage/provider shape is chosen.
- Use `@designer` if the recent-items list needs mobile layout polish.
