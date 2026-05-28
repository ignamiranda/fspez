# Handoff: Subreddit sidebar/about details

## Approved feature

Implement **subreddit sidebar/about details**.

## Current goal

Implement features to reach feature parity with the official Reddit mobile app, prioritizing mobile-app parity and mobile-quality UX.

## Scope

1. Fetch subreddit about data, likely `/r/{subreddit}/about.json` or the verified equivalent.
2. Show description/sidebar text, member count, online count, created date, and community indicators.
3. Include NSFW, quarantine, restricted, private, and related status indicators when available.
4. Expose details from the subreddit page in a mobile-friendly about panel/screen.
5. Defer links and full mod list if needed; moderator list has its own handoff.

## Existing related code

- `lib/src/presentation/screens/subreddit_feed_screen.dart`
- `lib/src/data/reddit_client.dart`
- Subreddit/community domain models under `lib/src/domain/models/`.

## Validation

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test` if tests are added/changed.
- Manual `flutter run`: open public, NSFW, and restricted/private/quarantined communities if available; confirm about details and error/empty states.
