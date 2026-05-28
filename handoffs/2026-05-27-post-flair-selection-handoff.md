# Handoff: Post flair selection on submit

## Approved feature

Implement **post flair selection during submit** for parity with the official Reddit mobile app.

## Current goal

Implement features to reach feature parity with the official Reddit mobile app.

## Why this feature

Existing submit flow appears to support text/link post creation, but not subreddit post flair selection. Official Reddit lets users select post flair and many communities require flair before submission.

## Existing related implementation

Inspect these areas first:

- `lib/src/presentation/screens/submit_screen.dart`
  - Current submit UI and state for text/link posts.
  - Add flair fetch/select/preview here or in a child widget.
- `lib/src/presentation/screens/subreddit_feed_screen.dart`
  - Existing subreddit submit entry point; may already pass subreddit context into submit flow.
- `lib/src/data/`
  - Existing submit repository/client methods and authenticated write patterns.
- `lib/src/domain/models/`
  - Add a post flair option model if none exists.
- `lib/src/data/api_responses.dart`
  - Add/manual parse flair option responses if consistent with existing response model style.

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

## Suggested implementation scope

Smallest useful vertical slice:

1. Fetch post flair options for the selected/target subreddit.
2. Show a flair selector in `SubmitScreen` when options exist.
3. Let the user select one flair and show a preview chip/label.
4. Submit the selected flair ID/text with the existing post submit request.
5. If Reddit reports flair is required, surface a clear validation error and keep the draft intact.

## Technical discovery needed

Before editing, inspect:

- Current `SubmitScreen` constructor/route arguments and whether subreddit is fixed or editable.
- Current submit method signature and request body.
- Existing API endpoint abstraction/domain selection for `POST /api/submit`.
- Whether `RedditClient.get()` auto-appends `.json` and how non-standard paths/query params are handled.
- Reddit flair endpoints available with cookie-only auth, likely requiring current validation against existing behavior/examples.

Potential endpoints/fields to verify before implementation:

- Post flair list endpoint for a subreddit.
- `flair_id` / `flair_text` / `resubmit` / `kind` fields accepted by submit.
- Whether flair requirements are discoverable before submit or only via submit errors.

## UX requirements

- Flair selector should appear only when a target subreddit is known and flair options are available.
- Selected flair should be visible before submission.
- If flair is required, do not let the failure look like a generic submit error.
- Keep existing text/link submit behavior intact for communities without flair.

## Deferred out of scope

- User flair selection.
- Editing flair after a post is submitted.
- Custom editable flair text unless required by fetched flair template metadata.
- Full subreddit rule validation beyond flair-required handling.
- Media post submission; separate handoff exists.

## Validation

Run after implementation:

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test` if tests are added/changed.
- Manual `flutter run` check recommended for a subreddit with optional flair and one that requires flair.

## Suggested skills / agents

- Reuse explorer session `exp-2 Check comment collapse` if more discovery is needed; it has already read `submit_screen.dart` and related presentation files.
- Use `reddit-api-auth` for Reddit flair/submit endpoint auth details if implementing write/API calls.
- Use `@librarian` if current external endpoint examples/docs are needed.
- Use `@fixer` for bounded implementation after endpoint behavior and file targets are clear.
- Use `@designer` only if the flair selector UI needs polish beyond standard Material controls.
