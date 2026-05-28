# Handoff: Report post/comment/user

## Approved feature

Implement **reporting for posts, comments, and users/profiles** for parity with the official Reddit mobile app.

## Current goal

Implement features to reach feature parity with the official Reddit mobile app.

## Why this feature

Existing app inventory did not show surfaced report actions. Official Reddit exposes reporting from post, comment, and profile overflow menus with a reason picker and confirmation feedback.

## Existing related implementation

Relevant areas to inspect first:

- `lib/src/presentation/widgets/post_card.dart`
  - Existing post action surface for vote/save/hide/delete/open actions.
- `lib/src/presentation/widgets/feed_screen_scaffold.dart`
  - Feed list and post interaction wiring.
- `lib/src/presentation/screens/post_detail_screen.dart`
  - Comment thread UI, reply/edit/delete actions, and post detail actions.
- `lib/src/presentation/screens/user_profile_screen.dart`
  - Profile UI where report user/profile action should live.
- `lib/src/data/`
  - Existing Reddit client/repository write patterns.

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

1. Add report action for posts and comments first.
   - Add overflow/menu entries where existing action patterns live.
   - Show a report reason picker dialog/sheet.
   - Submit the report to Reddit.
   - Show success/error feedback.
2. Add report action for user/profile after post/comment flow works.
3. Keep UI consistent with current Material styling and existing action affordances.

## Technical discovery needed

Before editing, inspect:

- Existing delete/hide/save action patterns and optimistic/error behavior.
- Existing `RedditClient` write operation helpers and endpoint/domain/header handling.
- Whether any report method already exists but is unused.
- Reddit API report endpoint requirements for cookie-only auth.

Likely Reddit endpoint candidates need verification before implementation. Do not assume endpoint shape without checking current behavior/docs/examples.

## Potential risks / open questions

- Report endpoints and reason taxonomies may differ for posts, comments, and users.
- Some report flows may require subreddit-specific rules/reasons.
- Cookie-only auth and modhash/header requirements need confirmation.
- A minimal generic reason picker may be acceptable for first slice, but official parity may require subreddit rule integration later.

## Deferred out of scope

- Subreddit-specific report rule fetch/display, unless straightforward.
- Moderator report queues/tools.
- Blocking user after report.
- Report status/history.
- Abuse-prevention UX beyond confirmation and error feedback.

## Validation

Run after implementation:

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test` if tests are added/changed.
- Manual check in `flutter run` recommended because report UI is interactive.

## Suggested skills / agents

- Use `@explorer` first if more discovery is needed; existing inventory session is `exp-2 Inventory implemented Reddit features`.
- Use `reddit-api-auth` for report endpoint/auth details if implementing write calls.
- Use `@librarian` only if external/current API docs/examples are needed.
- Use `@fixer` for bounded implementation after endpoint behavior and file targets are clear.
- Use `@oracle` if deciding between generic report reasons vs subreddit-rule-specific report UX.
