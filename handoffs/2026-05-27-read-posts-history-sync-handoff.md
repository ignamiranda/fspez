# Handoff: Read posts history sync

## Approved feature

Implement **read posts history sync / read indicators** for parity with the official Reddit mobile app.

## Current goal

Implement features to reach feature parity with the official Reddit mobile app.

## Why this feature

Official Reddit visually distinguishes posts a user has already opened/read and maintains user history. The app has account history surfaces, but a specific feed-level read-state workflow was not identified in the existing feature inventory.

## Existing related implementation

Inspect these areas first:

- `lib/src/presentation/widgets/feed_screen_scaffold.dart`
  - Feed list and post tap/navigation wiring.
- `lib/src/presentation/widgets/post_card.dart`
  - Candidate location for dim/read styling.
- `lib/src/presentation/screens/post_detail_screen.dart`
  - Opening a post should mark it read.
- `lib/src/presentation/screens/account_screen.dart`
  - Existing saved/hidden/history entry points; inspect current history implementation.
- `lib/src/data/`
  - Existing feed/history repositories, notifiers, and persistence providers.
- `lib/main.dart`
  - SharedPreferences are initialized and overridden into `ProviderScope`; use existing persistence patterns.

Already implemented features to avoid re-suggesting as new work:

- Feed browsing/sorting/refresh/pagination.
- Search across posts/communities/comments/media/profiles.
- Subreddit browsing and subscribe/unsubscribe.
- User profiles.
- Regular inbox/messages and compose.
- Text/link post submit.
- Saved/hidden/history screens.
- Multi-account auth/session switching.
- Fullscreen media/gallery/video viewing.
- Basic comment collapse/expand.
- Post/comment body editing, with a separate handoff for remaining edit gaps.

Related approved handoffs:

- `handoffs/2026-05-27-in-app-settings-screen-handoff.md`
- `handoffs/2026-05-27-adaptive-image-scaling-handoff.md`

## Suggested implementation scope

Smallest useful vertical slice:

1. Add local read-state tracking keyed by Reddit post fullname/id.
2. Mark a post as read when the user opens it from feed/search/subreddit/profile lists.
3. Show read styling in `PostCard`.
   - Example: dim title/metadata slightly or reduce emphasis without harming accessibility.
4. Persist read state locally across app restarts.
5. Add a setting to disable read indicators if the settings screen exists, or defer the toggle until that handoff is implemented.
6. Investigate Reddit history sync after local behavior is stable.

## Technical discovery needed

Before editing, inspect:

- Current history screen/data implementation and whether it already records opened posts.
- Existing post IDs/fullnames available in `Post` model.
- All navigation paths that open `PostDetailScreen`.
- Whether SharedPreferences is sufficient or if a larger local store is needed for many read IDs.
- Existing theme/style conventions for lower-emphasis text.

Reddit history sync may require additional endpoint behavior; do not assume it is available or reliable with cookie-only auth. Prefer local read indicators first.

## UX requirements

- Read styling should be visible but subtle.
- Marking read should happen immediately on open, not only after a successful network refresh.
- Read state should apply consistently across home, subreddit, search, profile, saved/history lists where post cards appear.
- If a disable setting is implemented, it should hide styling without deleting read history.

## Deferred out of scope

- Full cloud sync across devices unless endpoint support is confirmed.
- Clearing all read history, unless trivial after local store exists.
- Per-subreddit read-state settings.
- Analytics or tracking beyond local post IDs.

## Validation

Run after implementation:

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test` if tests are added/changed.
- Manual `flutter run` check:
  - Open a post from feed and return.
  - Confirm it appears read/dimmed.
  - Restart app and confirm state persists.
  - Check same post in another list if practical.

## Suggested skills / agents

- Reuse explorer session `exp-2 Check post edit implementation` for feed/post/detail context if more discovery is needed.
- Use `@fixer` for bounded implementation after read-state ownership and persistence target are known.
- Use `@designer` if read styling needs accessibility/visual polish.
- Use `@oracle` only if deciding between SharedPreferences, history repository reuse, or a larger persistence model becomes ambiguous.
