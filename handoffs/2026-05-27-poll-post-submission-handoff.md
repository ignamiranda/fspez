# Handoff: Poll post submission

## Approved feature

Implement **poll post submission** for parity with the official Reddit mobile app.

## Current goal

Implement features to reach feature parity with the official Reddit mobile app.

## Why this feature

The existing submit flow supports text/link posts, and separate handoffs exist for media submission and flair selection. Official Reddit also supports creating poll posts with multiple options and a duration.

## Existing related implementation

Inspect these areas first:

- `lib/src/presentation/screens/submit_screen.dart`
  - Current submit UI for text/link posts.
  - Likely place to add a poll post type or route to a dedicated poll submit screen.
- `lib/src/presentation/screens/subreddit_feed_screen.dart`
  - Existing subreddit submit entry point.
- `lib/src/data/reddit_client.dart`
  - Existing submit/write endpoint patterns.
- `lib/src/data/`
  - Existing submit repository/notifier providers, if split out from the client.
- `lib/src/domain/models/`
  - Add poll draft/options model if useful.

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
- Basic comment collapse/expand.
- Post/comment body editing, with a separate handoff for remaining edit gaps.

## Suggested implementation scope

Smallest useful vertical slice:

1. Add a poll post type in the submit UI.
2. Let the user enter:
   - Post title.
   - Target subreddit.
   - Poll options, minimum 2.
   - Poll duration, using Reddit-supported limits.
3. Validate locally before submit:
   - Title required.
   - Subreddit required.
   - At least 2 non-empty options.
   - No duplicate/blank options.
   - Duration within supported range.
4. Submit as a Reddit poll post using the correct endpoint/flow.
5. Preserve draft input on submit failure and show clear error feedback.

## Technical discovery needed

Before editing, inspect:

- Current submit method signature and request body in `reddit_client.dart` and related data layer files.
- Whether existing `POST /api/submit` flow can create polls or if a different endpoint is required.
- Cookie-only auth/modhash/domain requirements for poll creation.
- Whether subreddit capabilities/rules indicate polls are allowed before submit.
- Existing form validation and loading/error patterns in `SubmitScreen`.

Do not assume endpoint details; verify current Reddit poll submission behavior before implementation.

## UX requirements

- Poll creation should feel like a submit mode, not a separate unrelated workflow.
- Add/remove option controls should be simple and keyboard-friendly on Windows desktop.
- Disable submit until required fields are valid.
- If a subreddit does not allow polls or Reddit rejects the request, show a specific error when possible.

## Deferred out of scope

- Voting in polls from feed/detail, unless already implemented and only needs display wiring.
- Editing poll options after submission.
- Poll result visualization improvements.
- Scheduled posts/drafts.
- Flair selection integration beyond not breaking the separate flair-selection feature handoff.

## Validation

Run after implementation:

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test` if tests are added/changed.
- Manual `flutter run` check for form validation, adding/removing options, failed submit, and a successful poll submit if safe/test account is available.

## Suggested skills / agents

- Reuse explorer session `exp-2 Check post edit implementation` for submit/client discovery if needed; it has already read `submit_screen.dart`, `subreddit_feed_screen.dart`, and `reddit_client.dart`.
- Use `reddit-api-auth` for endpoint/auth details if implementing Reddit poll creation calls.
- Use `@librarian` if current external endpoint examples/docs are needed.
- Use `@fixer` for bounded implementation after endpoint behavior and file targets are clear.
- Use `@designer` only if the poll option editor UI needs polish beyond standard Material form controls.
