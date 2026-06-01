# Handoff: Modmail access

## Approved feature

Implement **modmail access** for parity with the official Reddit mobile app/moderator experience.

## Current goal

Implement features to reach feature parity with the official Reddit mobile app.

## Why this feature

Official Reddit exposes modmail for accounts that moderate communities. Existing inventory confirmed regular inbox/messages and compose, but no modmail surfaces were identified.

## Existing related implementation

Inspect these areas first:

- `lib/src/presentation/screens/inbox_screen.dart`
  - Existing message/inbox UI patterns that may be reusable.
- `lib/src/data/inbox_repository.dart`
  - Existing message fetch/reply patterns.
- `lib/src/data/inbox_notifier.dart`
  - Existing pagination/loading state patterns for message-like lists.
- `lib/src/presentation/screens/account_screen.dart`
  - Candidate entry point for Modmail, shown only for moderator accounts if detectable.
- `lib/src/presentation/screens/subreddit_feed_screen.dart`
  - Possible community-specific modmail entry point if account moderates that subreddit.
- `lib/src/data/reddit_client.dart`
  - Existing authenticated GET/POST helpers and endpoint/domain handling.

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

1. Detect whether the current account moderates any communities or whether modmail endpoint access is available.
2. Add a Modmail entry point from Account or Inbox.
   - Hide it or show an explanatory empty state for non-moderators.
3. Fetch and list modmail conversations.
4. Open a conversation and show messages chronologically.
5. Add reply support only after read-only conversation viewing works.

## Technical discovery needed

Before editing, inspect:

- Current account/current-user provider shape and whether moderated subreddits are already known.
- Existing inbox models and whether they can be reused or should stay separate from modmail models.
- Reddit modmail endpoint requirements and response shape.
- Cookie-only auth viability for new modmail endpoints.
- Existing pagination conventions for message/conversation lists.

Do not assume modmail endpoint shape; verify current Reddit behavior before implementation. New modmail may use different API paths/auth expectations than legacy inbox endpoints.

## UX requirements

- Non-moderators should not see broken modmail UI.
- Conversations should clearly show subreddit/context, participant, unread state if available, and last updated time.
- Read-only first slice is acceptable if write/reply endpoint is uncertain.
- Preserve existing regular Inbox behavior.

## Deferred out of scope

- Archive/highlight/mute modmail actions.
- Advanced filters beyond the first useful inbox/recent view.
- Bulk actions.
- Moderator permission management.
- Push/background notifications for modmail.

## Validation

Run after implementation:

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test` if tests are added/changed.
- Manual `flutter run` check with a moderator account and a non-moderator account if available.

## Suggested agents

- Reuse explorer session `exp-1 Find inbox implementation` for inbox/message architecture context if more discovery is needed.
- Use `reddit-api-auth` for endpoint/auth details if implementing modmail API calls.
- Use `@librarian` if current external endpoint examples/docs are needed.
- Use `@fixer` for bounded implementation after endpoint/model/UI targets are confirmed.
- Use `@oracle` if deciding whether to reuse inbox state/models or create separate modmail architecture is ambiguous.
