# Handoff: Moderation queue

## Approved feature

Implement a **moderation queue** for parity with the official Reddit mobile app/moderator experience.

## Current goal

Implement features to reach feature parity with the official Reddit mobile app.

## Why this feature

Official Reddit exposes moderation queues for accounts that moderate communities. Existing inventory confirmed normal browsing, posting, inbox, profiles, and account utilities, but no moderator queue surfaces were identified.

## Existing related implementation

Inspect these areas first:

- `lib/src/presentation/screens/account_screen.dart`
  - Candidate entry point for moderator tools, shown only for moderator accounts if detectable.
- `lib/src/presentation/screens/subreddit_feed_screen.dart`
  - Possible subreddit-specific moderation entry point if the current account moderates that subreddit.
- `lib/src/presentation/widgets/post_card.dart`
  - Existing post action/menu patterns that may be reused for approve/remove/spam actions.
- `lib/src/presentation/screens/post_detail_screen.dart`
  - Existing post/comment UI and action patterns; moderation queue items may navigate here.
- `lib/src/data/reddit_client.dart`
  - Existing authenticated GET/POST helpers and endpoint/domain handling.
- Existing feed pagination/state code
  - Reuse listing pagination patterns where possible.

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

Related approved moderator/community handoffs:

- `handoffs/2026-05-27-modmail-access-handoff.md`
- `handoffs/2026-05-27-moderator-list-display-handoff.md`
- `handoffs/2026-05-27-subreddit-rules-display-handoff.md`
- `handoffs/2026-05-27-subreddit-sidebar-about-details-handoff.md`

## Suggested implementation scope

Smallest useful vertical slice:

1. Detect whether the current account moderates any communities or whether modqueue endpoint access is available.
2. Add a Moderator Tools / Mod Queue entry point from Account.
   - Hide it or show an explanatory empty state for non-moderators.
3. Fetch modqueue items for all moderated communities or one selected subreddit.
4. Display queued posts/comments with:
   - Title/body preview.
   - Author.
   - Subreddit.
   - Report/filter reason if available.
   - Timestamp.
5. Add approve/remove actions after read-only listing works.
6. Add spam action and subreddit filter after approve/remove are stable.

## Technical discovery needed

Before editing, inspect:

- Current auth/current-user state and whether moderated subreddits are already known.
- Existing listing/feed pagination abstractions that can support modqueue pagination.
- Existing post/comment model reuse vs need for a separate moderation item model.
- Reddit modqueue endpoint requirements and response shape.
- Reddit approve/remove/spam endpoint auth requirements with cookie-only auth.
- Existing action feedback patterns for write operations.

Do not assume endpoint details; verify current Reddit behavior before implementation. Moderator endpoints may require permissions and may behave differently for posts vs comments.

## UX requirements

- Non-moderators should not see broken moderator tooling.
- Queue items should make it obvious why content is in the queue when Reddit provides a reason.
- Approve/remove/spam actions should require confirmation or offer undo/error feedback consistent with existing destructive action patterns.
- Keep moderator tools separate enough that normal users are not confused.

## Deferred out of scope

- Full moderation dashboard.
- Modmail; separate handoff exists.
- Ban/mute user tools.
- Removal reasons macros.
- Automoderator configuration.
- Bulk moderation actions.
- Moderator permissions management.

## Validation

Run after implementation:

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test` if tests are added/changed.
- Manual `flutter run` check with a moderator account and a non-moderator account if available.

## Suggested agents

- Reuse explorer session `exp-2 Check post edit implementation` for post/detail/client/subreddit context if more discovery is needed.
- Use `reddit-api-auth` for endpoint/auth details if implementing moderator API calls.
- Use `@librarian` if current external endpoint examples/docs are needed.
- Use `@fixer` for bounded implementation after endpoint/model/UI targets are confirmed.
- Use `@oracle` if deciding whether moderation items should reuse feed/comment models or use a separate moderation domain model is ambiguous.
