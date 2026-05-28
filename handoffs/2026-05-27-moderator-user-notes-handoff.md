# Handoff: Moderator user notes

## Approved feature

Implement **user notes for moderators** for parity with Reddit moderator tooling.

## Current goal

Implement features to reach feature parity with the official Reddit mobile app.

## Why this feature

Moderators often need subreddit-specific context about users. Official/new Reddit moderator tooling supports user notes or adjacent moderation history workflows. Existing inventory did not identify any surfaced moderator user-notes feature.

## Existing related implementation

Inspect these areas first:

- `lib/src/presentation/screens/user_profile_screen.dart`
  - Primary place to show a moderator-only notes entry/summary for a user.
- `lib/src/presentation/screens/post_detail_screen.dart`
  - Comments/posts expose authors; possible entry point to view/add a note about an author.
- `lib/src/presentation/widgets/post_card.dart`
  - Post author action surface may be a secondary entry point.
- `lib/src/presentation/screens/account_screen.dart`
  - Candidate entry point for moderator tools if a broader moderator section exists.
- `lib/src/data/reddit_client.dart`
  - Existing authenticated GET/POST helpers and endpoint/domain handling.
- `lib/src/domain/models/` and `lib/src/data/api_responses.dart`
  - Add moderator note models/parsing if none exist.

Related approved moderator handoffs:

- `handoffs/2026-05-27-modmail-access-handoff.md`
- `handoffs/2026-05-27-moderation-queue-handoff.md`
- `handoffs/2026-05-27-moderator-removal-reasons-handoff.md`
- `handoffs/2026-05-27-moderator-list-display-handoff.md`

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

1. Detect moderator context/permissions for a subreddit where notes are being viewed or added.
2. Add a moderator-only **User notes** entry on `UserProfileScreen` when viewing a user in a moderated subreddit context.
3. Fetch existing notes for that user/subreddit.
4. Display note list with:
   - Note text.
   - Moderator author if available.
   - Timestamp.
   - Label/type if available.
   - Linked content/context if available.
5. Add a basic “Add note” flow after read-only display works.

## Technical discovery needed

Before editing, inspect:

- Whether current profile navigation carries subreddit context; if not, decide how to choose a subreddit for notes.
- Current user/profile provider and model shape.
- Reddit endpoint(s) for moderator user notes, their auth requirements, and response shape.
- Whether cookie-only auth can access the required mod-note APIs.
- Existing form/dialog patterns for adding text input.

Do not assume endpoint details. Verify current Reddit behavior before implementation; user notes may be part of newer moderator APIs and may not behave like old Reddit endpoints.

## UX requirements

- Only show user notes to moderators with permission.
- Notes must be clearly scoped to a subreddit/community.
- If no subreddit context is available, prompt the moderator to choose a moderated subreddit or hide the entry.
- Non-moderators should never see broken moderator-only UI.
- Adding a note should preserve entered text on API failure.

## Deferred out of scope

- Full moderation dashboard.
- Bulk notes or advanced note search.
- Editing/deleting notes unless endpoint support is straightforward.
- Ban/mute integration.
- Third-party toolbox compatibility unless explicitly required later.

## Validation

Run after implementation:

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test` if tests are added/changed.
- Manual `flutter run` check with a moderator account and a non-moderator account if available.

## Suggested skills / agents

- Reuse explorer session `exp-2 Check post edit implementation` for profile/post/detail/client context if more discovery is needed.
- Use `reddit-api-auth` for endpoint/auth details if implementing moderator API calls.
- Use `@librarian` if current external endpoint examples/docs are needed.
- Use `@fixer` for bounded implementation after endpoint/model/UI targets are confirmed.
- Use `@oracle` if deciding how to represent subreddit-scoped moderator context in profile navigation is ambiguous.
