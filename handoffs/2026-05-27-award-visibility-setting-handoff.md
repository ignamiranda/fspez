# Handoff: Award visibility with disable setting

## Approved feature

Implement **post/comment award visibility**, with a user setting to disable/hide awards because the user explicitly wants awards visibility optional.

User approval: `yes but with a setting to disable visibility because awards are lameeee`

## Current goal

Implement features to reach feature parity with the official Reddit mobile app.

## Why this feature

Official Reddit surfaces awards/gilding on posts and comments. The app inventory did not identify award display. However, awards should be hideable via settings so users who dislike awards can suppress them.

## Existing related implementation

Inspect these areas first:

- `lib/src/presentation/widgets/post_card.dart`
  - Candidate location for award count/icons on feed cards.
- `lib/src/presentation/screens/post_detail_screen.dart`
  - Candidate location for award display on post header and comments.
- `lib/src/domain/models/post.dart`
  - Check whether award/gilding fields already exist.
- `lib/src/domain/models/comment.dart`
  - Check whether award/gilding fields already exist.
- `lib/src/data/api_responses.dart`
  - Check Reddit JSON fields for awards/gilding and add parsing if missing.
- `lib/src/presentation/screens/account_screen.dart` or any settings/preferences file
  - Candidate location for a toggle like “Show awards”.
- `lib/main.dart`
  - SharedPreferences are initialized and overridden into Riverpod provider scope; use existing preferences patterns.

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

1. Add parsing/model support for award/gilding metadata on posts and comments.
   - At minimum, support a visible aggregate count if Reddit JSON exposes it.
   - Prefer read-only display first.
2. Add UI display for awards/gilding.
   - Feed post cards.
   - Post detail header.
   - Comments in post detail.
3. Add a persisted setting: **Show awards**.
   - Default: enabled, for Reddit parity.
   - When disabled, hide award UI everywhere.
   - Store with existing SharedPreferences/Riverpod settings pattern if present.
4. Keep gifting/buying awards out of scope.

## Technical discovery needed

Before editing, inspect:

- Existing post/comment model fields and JSON parsing.
- Current settings/preferences architecture, if any.
- Current post/comment metadata row UI patterns.
- Existing tests for post/comment parsing that may need updates.

Potential Reddit JSON fields to investigate include `all_awardings`, `total_awards_received`, `gilded`, `gildings`, and related comment/post fields. Verify against existing API response models before adding fields.

## UX requirements

- Award visibility must be globally disableable.
- The setting should be easy to find, likely from Account/settings/preferences.
- When disabled, no award icons/counts/details should appear on posts or comments.
- Avoid making awards visually dominant; keep display subtle.

## Deferred out of scope

- Award gifting/purchasing.
- Coin balance or premium upsells.
- Complex award detail sheets unless aggregate display is already done.
- Animations/highlight effects.

## Validation

Run after implementation:

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test` if model/parser tests are added or updated.
- Manual `flutter run` check recommended for setting toggle and award visibility in feed/detail/comment surfaces.

## Suggested skills / agents

- Use existing explorer inventory session if more discovery is needed: `exp-2 Inventory implemented Reddit features`.
- Use `@fixer` for bounded model/parser/UI/settings implementation after fields and settings pattern are known.
- Use `@designer` if award display needs visual polish so it stays subtle and non-annoying.
- Use `@oracle` only if settings/state ownership is unclear.
