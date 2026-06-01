# Handoff: Moderator ban / unban users

## Approved feature

Implement **ban and unban users for moderators** for parity with the official Reddit mobile app/moderator experience.

## Current goal

Implement features to reach feature parity with the official Reddit mobile app.

## Why this feature

Official Reddit lets moderators ban users from moderated communities, choose temporary/permanent duration, provide ban reasons/mod notes, and unban users later. Existing inventory did not identify surfaced moderator ban/unban tooling.

## Existing related implementation

Inspect these areas first:

- `lib/src/presentation/screens/user_profile_screen.dart`
  - Primary place to expose moderator-only ban/unban actions for a viewed user.
- `lib/src/presentation/screens/post_detail_screen.dart`
  - Comments/posts expose authors; possible entry point to ban an author from a moderated subreddit.
- `lib/src/presentation/widgets/post_card.dart`
  - Post author/action surface may be a secondary entry point.
- `lib/src/presentation/screens/account_screen.dart`
  - Candidate entry point for moderator tools if a broader moderator section exists.
- `lib/src/data/reddit_client.dart`
  - Existing authenticated GET/POST helpers and endpoint/domain handling.
- `lib/src/domain/models/` and `lib/src/data/api_responses.dart`
  - Add ban/user relationship models/parsing if none exist.

Related approved moderator handoffs:

- `handoffs/2026-05-27-modmail-access-handoff.md`
- `handoffs/2026-05-27-moderation-queue-handoff.md`
- `handoffs/2026-05-27-moderator-removal-reasons-handoff.md`
- `handoffs/2026-05-27-moderator-user-notes-handoff.md`
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

1. Detect moderator context/permissions for the relevant subreddit.
2. Add moderator-only **Ban user** action from `UserProfileScreen` when a subreddit context is available.
3. Add a ban form with:
   - Target subreddit.
   - Permanent vs temporary ban.
   - Temporary ban duration when selected.
   - Ban reason.
   - Optional mod note.
   - Optional message to user if supported.
4. Submit ban via the correct Reddit moderator endpoint.
5. Add unban support when banned state is visible or from a banned-users management screen.
6. Add post/comment author entry points after the profile flow works.

## Technical discovery needed

Before editing, inspect:

- Whether profile navigation carries subreddit context; if not, decide how moderators choose the target subreddit.
- Current auth/current-user state and whether moderated subreddits/permissions are already known.
- Existing destructive confirmation/dialog/form patterns.
- Reddit endpoint(s) for banning and unbanning users, auth requirements, and response shape.
- Whether cookie-only auth/modhash works for the required moderator endpoints.

Do not assume endpoint details. Verify current Reddit behavior before implementation; moderator endpoints may differ from normal write endpoints.

## UX requirements

- Only show ban/unban actions to moderators with permission.
- Clearly scope the action to a subreddit/community.
- Distinguish temporary vs permanent bans.
- Confirm destructive actions and preserve entered form data on API failure.
- Non-moderators should never see broken moderator-only UI.

## Deferred out of scope

- Full banned-users management dashboard unless needed for unban.
- Bulk ban/unban.
- Ban evasion tooling.
- Automoderator integration.
- Modmail integration beyond optional user message if endpoint supports it.

## Validation

Run after implementation:

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test` if tests are added/changed.
- Manual `flutter run` check with a moderator account and a non-moderator account if available.

## Suggested agents

- Reuse explorer session `exp-2 Check post edit implementation` for profile/post/detail/client context if more discovery is needed.
- Use `reddit-api-auth` for endpoint/auth details if implementing moderator API calls.
- Use `@librarian` if current external endpoint examples/docs are needed.
- Use `@fixer` for bounded implementation after endpoint/model/UI targets are confirmed.
- Use `@oracle` if deciding how to represent subreddit-scoped moderator context in profile navigation is ambiguous.
