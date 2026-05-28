# Handoff: Share and copy link actions

## Approved feature

Implement **share / copy actions** for posts and comments.

## Current goal

Implement features to reach feature parity with the official Reddit mobile app.

## Why this feature

The official Reddit app exposes common sharing actions from post/comment overflow menus. This app has post/comment interaction menus, but copy/share actions were not identified in the current feature inventory.

## Existing related implementation

Inspect these areas first:

- `lib/src/presentation/widgets/post_card.dart`
  - Post overflow menu; currently includes actions like save/hide/delete/edit.
- `lib/src/presentation/widgets/comment_tree.dart`
  - Comment action row/reply/edit/delete/collapse behavior.
- `lib/src/presentation/screens/post_detail_screen.dart`
  - Post detail header and comment tree integration.
- `lib/src/domain/models/post.dart`
  - Available post permalink, url, selftext, title, subreddit, and author fields.
- `lib/src/domain/models/comment.dart`
  - Available comment permalink/body/context fields.

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

- `handoffs/2026-05-27-local-drafts-handoff.md`
- `handoffs/2026-05-27-report-content-handoff.md`
- `handoffs/2026-05-27-crosspost-creation-handoff.md`

## Suggested implementation scope

Smallest useful vertical slice:

1. Add post overflow actions:
   - Copy Reddit link/permalink.
   - Copy external link when the post has a non-Reddit target URL.
   - Copy title/text for text posts.
   - Share via platform share API if a suitable Flutter desktop-compatible package is already present or can be added safely.
2. Add comment actions:
   - Copy comment link/permalink.
   - Copy comment text/body.
   - Share comment link if platform share support exists.
3. Show lightweight confirmation feedback after copy/share actions.
4. Keep actions grouped and labeled clearly so overflow menus do not become confusing.

## Technical discovery needed

Before editing, inspect:

- Existing dependencies in `pubspec.yaml` for clipboard/share support.
- Whether `Clipboard` from Flutter services is already used.
- Exact shape of post/comment permalink fields and whether they are relative paths that need `https://www.reddit.com` prefixing.
- Whether external post URLs may be Reddit-hosted media URLs and how to label them.
- Current snackbar/toast pattern for user feedback.

## UX requirements

- Copy actions should work on Windows desktop.
- Link text should be full absolute URLs, not relative `/r/...` paths.
- If an action is not applicable, hide it rather than showing a disabled dead item.
- Confirmation should be brief: e.g. “Copied Reddit link”.
- Avoid accidental duplicate labels between “Copy Reddit link” and “Copy external link”.

## Deferred out of scope

- OS-level share sheet if desktop support is unreliable or requires broad dependency work.
- Sharing images/videos as files.
- Generating short links.
- Deep-link routing back into this app.
- Analytics/tracking.

## Validation

Run after implementation:

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test` if tests are added/changed.
- Manual `flutter run` checks:
  - Copy Reddit link from a feed post and paste it elsewhere; confirm it is absolute and opens the post.
  - Copy external link from a link post; confirm it matches the target URL.
  - Copy text from a text post and comment.
  - Confirm unavailable actions are hidden for posts/comments that do not support them.

## Suggested skills / agents

- Reuse explorer session `exp-2 Check post edit implementation` for post/comment overflow context if more discovery is needed.
- Use `@fixer` for bounded implementation after action list and link normalization are clear.
- Use `@designer` only if overflow/menu organization needs polish.
