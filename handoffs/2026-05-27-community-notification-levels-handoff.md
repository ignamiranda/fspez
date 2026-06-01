# Handoff: Community notification level controls

## Approved feature

Implement **per-community notification level controls** similar to the official Reddit mobile app.

## Current goal

Implement features to reach feature parity with the official Reddit mobile app.

## Why this feature

The official Reddit app lets users tune notifications for joined communities separately from joining/leaving. This app supports subreddit browsing and subscribe/unsubscribe, but no per-subreddit notification controls were identified.

## Existing related implementation

Inspect these areas first:

- `lib/src/presentation/screens/subreddit_feed_screen.dart`
  - Subreddit header and subscribe/unsubscribe controls.
- `lib/src/data/reddit_client.dart`
  - Current subreddit subscription and write-operation patterns.
- `lib/src/data/`
  - Subreddit repository/notifier/provider patterns.
- `lib/src/domain/models/`
  - Subreddit/community models and available notification-related fields, if any.
- `lib/src/presentation/screens/account_screen.dart`
  - Possible entry point for a future joined-community notification management surface.

Already implemented features to avoid re-suggesting as new work:

- Feed browsing/sorting/refresh/pagination.
- Post interactions: vote/save/hide/delete/edit body/open links.
- Post detail/comments/replies/media/link display.
- Search posts/communities/comments/media/profiles.
- Subreddit view subscribe/unsubscribe/submit.
- User profiles.
- Inbox All/Unread/Sent with message threads/reply/compose.
- Direct message compose.
- Text/link post submit.
- Account multi-account add/remove/switch/logout.
- Saved/hidden/history screens.
- WebView auth.
- Fullscreen media viewer/gallery/video.
- Basic comment collapse/expand.

Related approved handoffs:

- `handoffs/2026-05-27-community-mute-unmute-handoff.md`
- `handoffs/2026-05-27-in-app-settings-screen-handoff.md`

## Suggested implementation scope

Smallest useful vertical slice:

1. Add a notification control to the subreddit page/header for joined communities.
2. Support common levels if Reddit endpoint support is confirmed:
   - Frequent / high.
   - Low.
   - Off.
3. Fetch current notification level when loading subreddit details if available.
4. Submit level changes through the correct Reddit endpoint with cookie-only auth.
5. Show loading, success, and error states without changing subscribe status.

## Technical discovery needed

Before editing, verify Reddit endpoint behavior. Do not assume modern app endpoints work with this app’s cookie-only auth.

Investigate:

- Whether old Reddit, www Reddit, or a GraphQL/private endpoint exposes subreddit notification preferences.
- Required headers, modhash, and domain.
- Whether notification settings are available only for joined communities.
- Whether the setting is per account and how multi-account switching should invalidate cached state.
- Whether existing subreddit about JSON includes notification level fields.

## UX requirements

- Keep notification controls visually distinct from subscribe/unsubscribe.
- Hide or disable notification levels for anonymous/non-authenticated states.
- If endpoint support is unavailable, do not ship a dead toggle; keep the UI hidden and document the blocker.
- Error copy should be specific: “Could not update community notifications”.
- Mute/unmute is a separate feature and should not be conflated with notification level off unless Reddit’s API proves they are the same operation.

## Deferred out of scope

- Push notification delivery infrastructure.
- Global notification settings.
- Joined-community notification management screen.
- Local simulated notifications.
- Community mute/unmute; covered by `community-mute-unmute-handoff`.

## Validation

Run after implementation:

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test` if tests are added/changed.
- Manual `flutter run` checks with an authenticated account:
  - Open a joined subreddit.
  - Change notification level.
  - Reload/reopen and confirm the selected level persists.
  - Try a non-joined subreddit and confirm the UI behaves correctly.
  - Confirm subscribe/unsubscribe still works independently.

## Suggested agents

- Use `@librarian` or `reddit-api-auth` guidance for endpoint/auth research before implementation.
- Reuse explorer session `exp-2 Check post edit implementation` for subreddit screen/client context if needed.
- Use `@fixer` for bounded implementation once endpoint behavior is verified.
- Use `@oracle` if endpoint behavior suggests notification off and community mute are semantically overlapping.
