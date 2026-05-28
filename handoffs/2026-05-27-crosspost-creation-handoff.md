# Handoff: Crosspost creation

## Approved feature

Implement **crosspost creation** for parity with the official Reddit mobile app.

## Current goal

Implement features to reach feature parity with the official Reddit mobile app.

## Why this feature

The existing app supports browsing feeds, viewing posts, subreddit pages, and text/link post submission. Official Reddit also lets users crosspost an existing post into another subreddit while preserving source attribution.

## Existing related implementation

Inspect these areas first:

- `lib/src/presentation/widgets/post_card.dart`
  - Candidate location for a post overflow/menu crosspost action.
- `lib/src/presentation/screens/post_detail_screen.dart`
  - Candidate location for a crosspost action from post detail.
- `lib/src/presentation/screens/submit_screen.dart`
  - Existing submit flow may be extended or reused for crosspost title/subreddit selection.
- `lib/src/presentation/screens/subreddit_feed_screen.dart`
  - Existing subreddit submit entry point and subreddit context handling.
- `lib/src/data/reddit_client.dart`
  - Existing authenticated submit/write endpoint patterns.
- `lib/src/domain/models/post.dart`
  - Existing post ID/name/permalink fields needed for source attribution.

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

1. Add a **Crosspost** action on post cards and/or post detail.
2. Open a crosspost form with:
   - Source post preview/summary.
   - Target subreddit input/selection.
   - Optional title override or prefilled source title, matching Reddit behavior.
3. Validate locally:
   - Target subreddit required.
   - Title required if Reddit requires it.
   - Source post must have a valid fullname/permalink/url required by the endpoint.
4. Submit via the correct Reddit crosspost flow.
5. Show success/error feedback and preserve draft input on failure.

## Technical discovery needed

Before editing, inspect:

- Existing post model fields: fullname/name, id, subreddit, title, permalink/url.
- Existing submit method request body and whether crosspost can reuse `/api/submit` with crosspost fields.
- Cookie-only auth/modhash/domain/header requirements for crosspost submission.
- Existing navigation/dialog patterns for post actions.
- Existing form validation/loading/error patterns in `SubmitScreen`.

Do not assume endpoint details; verify current Reddit crosspost behavior before implementation.

## UX requirements

- Crosspost should be accessible from existing post action surfaces.
- The form should clearly show the source post being crossposted.
- Do not confuse crosspost with ordinary link submission.
- If Reddit rejects a target subreddit because crossposts are disabled, show a specific error when possible.

## Deferred out of scope

- Crosspost recommendations.
- Multi-subreddit crossposting.
- Flair selection integration unless needed by the target subreddit; a separate post-flair handoff exists.
- Media upload; separate media submission handoff exists.
- Poll submission; separate poll handoff exists.

## Validation

Run after implementation:

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test` if tests are added/changed.
- Manual `flutter run` check for opening crosspost flow from feed/detail, validation errors, and submit failure/success if safe.

## Suggested skills / agents

- Reuse explorer session `exp-2 Check post edit implementation` for submit/client/post-detail discovery if needed.
- Use `reddit-api-auth` for endpoint/auth details if implementing Reddit crosspost calls.
- Use `@librarian` if current external endpoint examples/docs are needed.
- Use `@fixer` for bounded implementation after endpoint behavior and file targets are clear.
- Use `@oracle` only if deciding whether crosspost belongs inside `SubmitScreen` or a dedicated crosspost screen is ambiguous.
