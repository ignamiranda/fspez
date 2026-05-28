# Handoff: Moderator removal reasons

## Approved feature

Implement **moderator removal reasons** for parity with the official Reddit mobile app/moderator experience.

## Current goal

Implement features to reach feature parity with the official Reddit mobile app.

## Why this feature

Official Reddit lets moderators choose subreddit-specific removal reasons when removing posts/comments, often linked to community rules. A separate moderation queue handoff exists; this feature completes the remove workflow beyond a generic remove action.

## Existing related implementation

Inspect these areas first:

- `handoffs/2026-05-27-moderation-queue-handoff.md`
  - Related approved modqueue feature where remove actions may be introduced.
- `handoffs/2026-05-27-subreddit-rules-display-handoff.md`
  - Related approved rules display feature; removal reasons may link to rules.
- `lib/src/presentation/widgets/post_card.dart`
  - Existing post action/menu patterns.
- `lib/src/presentation/screens/post_detail_screen.dart`
  - Existing post/comment action patterns.
- `lib/src/presentation/screens/subreddit_feed_screen.dart`
  - Community context and potential moderator entry points.
- `lib/src/data/reddit_client.dart`
  - Existing authenticated GET/POST helpers and endpoint/domain handling.
- `lib/src/domain/models/` and `lib/src/data/api_responses.dart`
  - Add removal reason models/parsing if none exist.

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

## Suggested implementation scope

Smallest useful vertical slice:

1. Fetch subreddit removal reasons for a moderated subreddit.
2. When a moderator removes a post/comment, show a removal reason picker.
3. Let moderators choose:
   - No reason / simple remove fallback.
   - A subreddit-defined reason.
4. Submit the remove action plus selected reason using the correct Reddit moderator flow.
5. Show success/error feedback and preserve the simple remove path if reason submission fails or is unsupported.

## Technical discovery needed

Before editing, inspect:

- Whether any remove/moderation methods already exist in `RedditClient`.
- Current delete/remove terminology in the app; do not confuse user delete with moderator remove.
- Reddit endpoint(s) for removal reasons and removal messages.
- Whether reasons are exposed through old Reddit endpoints, new mod endpoints, or GraphQL-like APIs.
- Cookie-only auth/modhash/domain/header requirements for moderator actions.

Do not assume endpoint details. Verify current Reddit behavior before implementation.

## UX requirements

- Only show removal-reason flow to moderators with permission.
- Keep a fast fallback for simple remove.
- Clearly distinguish “remove from community” from “delete my content”.
- If removal reason can send a comment/message, make that explicit before sending.
- Avoid blocking remove if reason fetch fails; allow generic remove with a warning.

## Deferred out of scope

- Full modqueue implementation; separate handoff exists.
- Editing/managing removal reason templates.
- Bulk removal reasons.
- Automoderator configuration.
- Ban/mute user actions.

## Validation

Run after implementation:

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test` if tests are added/changed.
- Manual `flutter run` check with a moderator account on a test subreddit if available.

## Suggested skills / agents

- Reuse explorer session `exp-2 Check post edit implementation` for post/detail/client/subreddit context if more discovery is needed.
- Use `reddit-api-auth` for endpoint/auth details if implementing moderator API calls.
- Use `@librarian` if current external endpoint examples/docs are needed.
- Use `@fixer` for bounded implementation after endpoint/model/UI targets are confirmed.
- Use `@oracle` if deciding how to integrate removal reasons with modqueue/rules architecture is ambiguous.
