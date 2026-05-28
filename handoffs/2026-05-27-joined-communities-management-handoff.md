# Handoff: Joined communities list and management

## Approved feature

Implement a **joined communities list / community management** surface.

## Current goal

Implement features to reach feature parity with the official Reddit mobile app.

## Why this feature

The official Reddit app gives users quick access to joined communities and basic community management. This app supports subreddit search and subscribe/unsubscribe from a subreddit page, but no joined-community list or management surface was identified.

## Existing related implementation

Inspect these areas first:

- `lib/src/presentation/screens/account_screen.dart`
  - Best initial entry point for a “Communities” or “Joined communities” item.
- `lib/src/presentation/screens/subreddit_feed_screen.dart`
  - Existing subreddit view and subscribe/unsubscribe behavior.
- `lib/src/presentation/screens/search_screen.dart`
  - Existing community search UI patterns.
- `lib/src/data/reddit_client.dart`
  - Existing subreddit subscription and listing endpoint patterns.
- `lib/src/data/`
  - Existing repository/notifier/provider conventions for paginated lists.
- `lib/src/domain/models/`
  - Existing subreddit/community model fields.

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
- `handoffs/2026-05-27-community-notification-levels-handoff.md`
- `handoffs/2026-05-27-subreddit-sidebar-about-details-handoff.md`

## Suggested implementation scope

Smallest useful vertical slice:

1. Add an Account screen entry for “Joined communities”.
2. Fetch the authenticated user’s subscribed communities with pagination.
3. Display community name, icon if available, title/description snippet, subscriber count if available, and NSFW/private/restricted indicators if available.
4. Support quick search/filter within the loaded list.
5. Tapping a community opens existing `SubredditFeedScreen`.
6. Add an unsubscribe action with confirmation, reusing the existing subscribe/unsubscribe client flow.
7. Refresh list state after unsubscribe.

## Technical discovery needed

Before editing, inspect/verify:

- Correct Reddit endpoint for subscribed subreddits under cookie-only auth.
  - Likely candidates include `/subreddits/mine/subscriber.json` or user-related subreddit listing endpoints, but verify against current client patterns.
- Whether the endpoint returns all needed icon/title/count fields or needs fallback display.
- Existing pagination abstractions and whether this can reuse `CursorPaginatedNotifier`.
- Existing subreddit model shape; avoid duplicating a second community model if one already fits.
- How multi-account switching should invalidate/refetch the joined-community list.

## UX requirements

- Empty state should distinguish “not logged in”, “no joined communities”, and loading/error.
- Unsubscribe must require confirmation to avoid accidental community removal.
- Search/filter should be local for the loaded page(s) unless full remote search is straightforward.
- Keep this distinct from community discovery/search; it is for already joined communities.

## Deferred out of scope

- Custom community ordering/favorites.
- Multireddits/custom feeds.
- Joined-community notification level controls; separate handoff exists.
- Mute/unmute management; separate handoff exists.
- Bulk unsubscribe.

## Validation

Run after implementation:

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test` if tests are added/changed.
- Manual `flutter run` checks with an authenticated account:
  - Open Account → Joined communities.
  - Confirm subscribed communities load and paginate.
  - Search/filter a loaded community.
  - Open a community and confirm it navigates to the existing subreddit page.
  - Unsubscribe from a test community, confirm prompt and list refresh.

## Suggested skills / agents

- Use `@librarian` or the `reddit-api-auth` skill if endpoint behavior is unclear.
- Reuse explorer session `exp-2 Check post edit implementation` for account/subreddit/client context if needed.
- Use `@fixer` for bounded implementation after endpoint/model reuse is clear.
- Use `@designer` if the community list layout needs visual polish.
