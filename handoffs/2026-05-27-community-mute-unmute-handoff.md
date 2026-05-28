# Handoff: Community mute / unmute

## Approved feature

Implement **community mute and unmute** for parity with the official Reddit mobile app.

## Current goal

Implement features to reach feature parity with the official Reddit mobile app.

## Why this feature

The app already supports feed browsing, subreddit pages, subscribe/unsubscribe, hidden/saved/history, profiles, inbox, and posting. No surfaced community mute/unmute flow was identified. Official Reddit lets users mute communities so they stop appearing in feeds and manage muted communities later.

## Existing related implementation

Inspect these areas first:

- `lib/src/presentation/screens/subreddit_feed_screen.dart`
  - Existing subreddit header and subscribe/unsubscribe action surface. Likely first place for mute/unmute.
- `lib/src/presentation/widgets/post_card.dart`
  - Candidate location for “mute community” from post overflow/menu.
- `lib/src/presentation/widgets/feed_screen_scaffold.dart`
  - Feed list and post action wiring.
- `lib/src/presentation/screens/account_screen.dart`
  - Existing account utility links; possible entry point for muted communities management.
- `lib/src/data/`
  - Existing Reddit client/repository write patterns for authenticated requests.

Already implemented features to avoid re-suggesting as new work:

- Feed browsing/sorting/refresh/pagination.
- Search across posts/communities/comments/media/profiles.
- Subreddit browsing and subscribe/unsubscribe.
- User profiles.
- Inbox/messages and compose.
- Text/link post submit.
- Saved/hidden/history screens.
- Multi-account auth/session switching.
- Fullscreen media/gallery/video viewing.

## Suggested implementation scope

Smallest useful vertical slice:

1. Add mute community action on `SubredditFeedScreen`.
   - Show confirmation dialog.
   - Submit mute request to Reddit.
   - Show success/error feedback.
   - Reflect muted state in UI if available.
2. Add “mute community” from post overflow/menu after subreddit-page flow works.
3. Add unmute support where muted state is visible.
4. Add muted communities management screen only after basic mute/unmute works.

## Technical discovery needed

Before editing, inspect:

- Whether mute/unmute methods already exist in data/client layers.
- Existing subreddit subscribe/unsubscribe method and UI patterns.
- Existing authenticated POST helper patterns and modhash/domain/header rules.
- Whether subreddit/about or relationship data includes muted state.
- Account/settings navigation patterns if adding a muted communities list.

Endpoint behavior needs verification before implementation. Do not assume endpoint shape. Cookie-only auth and modhash/header/domain requirements may differ from save/submit/comment flows.

## Potential risks / open questions

- Reddit community mute endpoints may be new/mobile-specific and less stable with cookie-only auth.
- Official app may distinguish mute from unsubscribe; keep those states separate.
- Server-side feed filtering may not immediately remove already-loaded posts; decide whether to optimistically remove posts from muted community in current feed.
- Unmute may require fetching current muted communities from preferences/settings endpoint.

## Deferred out of scope

- Full muted-communities settings screen, unless needed for unblock-style management.
- Global feed re-filtering across every loaded provider.
- Community recommendations suppression beyond Reddit’s mute endpoint.
- Blocking users or reporting content; those have separate handoffs.

## Validation

Run after implementation:

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test` if tests are added/changed.
- Manual `flutter run` check recommended for confirmation dialogs, subreddit page action, and post overflow action.

## Suggested skills / agents

- Use `@explorer` first only if more discovery is needed; existing inventory session is `exp-2 Inventory implemented Reddit features`.
- Use `reddit-api-auth` for endpoint/auth details if implementing Reddit write calls.
- Use `@librarian` if current external endpoint examples/docs are needed.
- Use `@fixer` for bounded implementation after endpoint behavior and file targets are clear.
- Use `@oracle` if deciding whether to optimistically filter loaded feeds or rely on server-side filtering.
