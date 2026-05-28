# Handoff: Comment sort selector

## Approved feature

Implement a **comment sort selector** on post detail screens.

## Current goal

Implement features to reach feature parity with the official Reddit mobile app, prioritizing mobile-app parity and mobile-quality UX.

## Scope

1. Add sort selector in `PostDetailScreen`.
2. Support Reddit comment sorts where available: Best, Top, New, Controversial, Old, and Q&A if supported.
3. Reload comments when sort changes.
4. Persist a default comment sort if settings infrastructure exists.
5. Handle unsupported sorts gracefully.

## Existing related code

- `lib/src/presentation/screens/post_detail_screen.dart`
- `lib/src/data/reddit_client.dart`
- Comment parsing/domain models under `lib/src/data/` and `lib/src/domain/models/`.

## Validation

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test` if tests are added/changed.
- Manual `flutter run`: open a post with many comments, change sort, confirm comments reload/reorder and selected sort persists if implemented.
