# Handoff: Block / unblock users

## Approved feature

Implement **block and unblock users** for parity with the official Reddit mobile app.

## Current goal

Implement features to reach feature parity with the official Reddit mobile app.

## Why this feature

The app already has feeds, profiles, post/comment interactions, inbox, saved/hidden/history, and posting, but no surfaced block/unblock flow was identified in the feature inventory. Official Reddit supports blocking users from profiles and content overflow menus, plus managing blocked users.

## Existing related implementation

Inspect these areas first:

- `lib/src/presentation/screens/user_profile_screen.dart`
  - Add block/unblock action on user profile.
- `lib/src/presentation/widgets/post_card.dart`
  - Add “block author” action from post overflow/menu if an overflow pattern exists.
- `lib/src/presentation/screens/post_detail_screen.dart`
  - Add block author action for comments and post detail contexts.
- `lib/src/presentation/screens/account_screen.dart`
  - Existing account utilities area may be a place to link to blocked users/settings.
- `lib/src/data/`
  - Existing Reddit client/repository write patterns for authenticated POSTs.

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

1. Add block user action from `UserProfileScreen`.
   - Show confirmation dialog.
   - Submit block request to Reddit.
   - Show success/error feedback.
   - Reflect blocked state in the UI if available.
2. Add block author actions from post/comment overflow menus.
3. Add unblock support where blocked state is visible.
4. Add a blocked-users management screen only after basic block/unblock works.

## Technical discovery needed

Before editing, inspect:

- Whether any block/unblock methods already exist in data/client layers.
- Existing authenticated POST helper patterns and modhash/domain/header rules.
- Existing profile model fields for blocked/is_friend/relationship state.
- Existing account/settings navigation patterns for adding a blocked users list.

Endpoint behavior needs verification before implementation; do not assume endpoint shape. Cookie-only auth and modhash requirements may differ from save/submit/comment flows.

## Potential risks / open questions

- Reddit block API may differ for old/new/mobile endpoints.
- Blocked-users list retrieval may require a separate preferences/settings endpoint.
- Local content filtering for blocked users could duplicate server-side behavior; first slice should avoid broad feed filtering unless API responses still include blocked authors.
- Unblock requires knowing or fetching current blocked state.

## Deferred out of scope

- Full blocked-users settings screen, unless basic unblock needs it.
- Automatic removal of all existing visible content by blocked users across every loaded feed.
- Blocking subreddit/community content.
- Mute community feature.
- Safety center/report-after-block flows.

## Validation

Run after implementation:

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test` if tests are added/changed.
- Manual `flutter run` check is recommended for confirmation dialogs and profile/menu flows.

## Suggested skills / agents

- Use `@explorer` first only if more discovery is needed; existing inventory session is `exp-2 Inventory implemented Reddit features`.
- Use `reddit-api-auth` for block/unblock endpoint/auth details if implementing Reddit write calls.
- Use `@librarian` if current external endpoint examples/docs are needed.
- Use `@fixer` for bounded implementation after endpoint behavior and file targets are clear.
- Use `@oracle` if deciding how much local filtering/state synchronization belongs in this slice.
