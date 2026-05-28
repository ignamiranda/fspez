# Handoff: Subreddit wiki pages

## Approved feature

Implement **subreddit wiki pages** for parity with the official Reddit mobile app.

## Current goal

Implement features to reach feature parity with the official Reddit mobile app.

## Why this feature

Official Reddit exposes community wiki pages for many subreddits. Existing inventory confirmed subreddit browsing, subscribe/unsubscribe, and several handoffs for rules/about details, but no wiki browsing flow was identified.

## Existing related implementation

Inspect these areas first:

- `lib/src/presentation/screens/subreddit_feed_screen.dart`
  - Existing subreddit page/header. Likely entry point for a Wiki action, possibly alongside About/Rules.
- `lib/src/data/reddit_client.dart`
  - Existing authenticated GET patterns and subreddit API helpers.
- `lib/src/domain/models/`
  - Add wiki page/index models if none exist.
- `lib/src/data/api_responses.dart`
  - Add manual parsing for wiki API responses if consistent with existing style.
- Existing link/opening and text rendering widgets
  - Reuse for wiki markdown links where possible.

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
- Basic comment collapse/expand.
- Post/comment body editing, with a separate handoff for remaining edit gaps.

Related approved handoffs that may interact with this work:

- `handoffs/2026-05-27-subreddit-rules-display-handoff.md`
- `handoffs/2026-05-27-subreddit-sidebar-about-details-handoff.md`

## Suggested implementation scope

Smallest useful vertical slice:

1. Add a Wiki entry point from `SubredditFeedScreen` or the future About area.
2. Fetch and display the subreddit wiki index.
3. Let users open a wiki page.
4. Render wiki page content read-only.
5. Support internal wiki links between pages if straightforward.
6. Handle disabled/private/missing wiki states gracefully.

## Technical discovery needed

Before editing, inspect:

- Current subreddit screen navigation/action patterns.
- `RedditClient.get()` behavior for paths with `.json` and query params.
- Whether the project already has markdown rendering dependency or custom markdown handling.
- Existing external/internal link handling utilities.
- Reddit wiki endpoints and response shape, likely paths such as:
  - `/r/{subreddit}/wiki/index.json`
  - `/r/{subreddit}/wiki/pages.json`
  - `/r/{subreddit}/wiki/{page}.json`

Verify endpoint behavior before implementation. Some wiki endpoints may fail for disabled/private/restricted wikis.

## UX requirements

- Wiki should be discoverable from community context, not global navigation.
- Page content should be scrollable and readable.
- Internal wiki links should not open an external browser if they can be handled in-app.
- Disabled/private/missing wiki should show a friendly message, not a generic crash/error.

## Deferred out of scope

- Editing wiki pages.
- Wiki revision history.
- Moderator wiki tools.
- Offline caching beyond simple provider memoization.
- Full markdown fidelity if the app does not already support markdown rendering.

## Validation

Run after implementation:

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test` if tests are added/changed.
- Manual `flutter run` check on a subreddit with a public wiki, one without/disabled wiki, and internal wiki links if available.

## Suggested skills / agents

- Reuse explorer session `exp-2 Check post edit implementation` for subreddit screen and client context if more discovery is needed.
- Use `@librarian` or Context7 if adding/using a markdown rendering package.
- Use `@fixer` for bounded implementation after endpoint/model/UI targets are confirmed.
- Use `@designer` only if the wiki reader needs layout polish.
- Use `@oracle` only if deciding shared architecture for Rules/About/Wiki community info surfaces becomes ambiguous.
