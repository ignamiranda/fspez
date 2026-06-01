# Handoff: Media post submission

## Approved feature

Implement **media post submission** for feature parity with the official Reddit mobile app.

## Current goal

Implement features to reach feature parity with the official Reddit mobile app.

## Why this feature

The repo already has strong media viewing support, but post creation appears limited to text/link submission. Official Reddit supports creating image, video, and gallery posts.

## Existing related implementation

From feature inventory:

- `lib/src/presentation/screens/submit_screen.dart`
  - Existing submit UI supports text/link post creation only.
  - Needs extension or sibling screen for media modes.
- `lib/src/presentation/screens/subreddit_feed_screen.dart`
  - Subreddit screen has create/submit entry point.
- `lib/src/presentation/widgets/media_viewer.dart`
  - Fullscreen media viewer already supports gallery swipe, zoom, and video playback.
- `lib/src/presentation/widgets/post_card.dart`
  - Existing feed cards render media posts.
- `lib/src/presentation/screens/post_detail_screen.dart`
  - Existing post detail renders media/link content.

Broader app features already coded, so do not re-suggest these as new work:

- Feed browsing and sorting.
- Search across posts/communities/comments/media/profiles.
- Subreddit browsing and subscribe/unsubscribe.
- User profiles.
- Inbox/messages and compose.
- Text/link post submit.
- Saved/hidden/history screens.
- Multi-account auth/session switching.

## Suggested implementation scope

Start with the smallest useful vertical slice:

1. Add **image post submission** first.
   - Pick image from local filesystem.
   - Preview selected image in submit UI.
   - Enter title and target subreddit.
   - Submit to Reddit using the correct media upload flow.
2. After image submission works, extend to:
   - Multiple images/gallery submission.
   - Video upload submission.
3. Keep existing text/link submission behavior intact.

## Technical discovery needed

Before editing, inspect:

- `lib/src/presentation/screens/submit_screen.dart`
- Submit-related methods in `lib/src/data/` (especially Reddit client/repository files)
- `pubspec.yaml` for existing file picker/image picker/upload dependencies
- Existing Reddit endpoint patterns for submit/auth/modhash/domain selection

Important project context:

- Reddit write ops are cookie-authenticated, no OAuth.
- Submit currently uses `POST /api/submit`, requires modhash, and uses `old.reddit.com` per `AGENTS.md` write-op table.
- Media upload may require endpoints/flows that differ from simple text/link submit; verify against current Reddit behavior before implementation.
- No `build_runner`; use manual models and existing patterns.

## Potential risks / open questions

- Reddit media uploads may require a multi-step upload flow rather than simple `/api/submit`.
- Official upload endpoints may be less stable with cookie-only auth.
- Windows desktop is the default target; choose picker/upload dependencies compatible with Flutter Windows.
- If media upload proves too large for one slice, implement UI/file selection/preview behind a disabled submit or feature flag only after confirming with user.

## Deferred out of scope

- Poll submission.
- Crosspost creation.
- Flair selection unless already easy from existing APIs.
- Drafts/scheduled posts.
- Advanced NSFW/spoiler/original-content controls unless trivial.

## Validation

Run after implementation:

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test` if any tests are added/changed.
- Manual `flutter run` check is recommended because this touches file picking/upload UI.

## Suggested agents

- Use `@explorer` first for submit/client/dependency discovery. Reuse existing inventory session if helpful: `exp-2 Inventory implemented Reddit features`.
- Use `@librarian` or Context7 for Flutter picker/upload package docs if adding or using a file/media picker dependency.
- Use `reddit-api-auth` if implementing or debugging Reddit upload/write endpoint behavior.
- Use `@oracle` if Reddit media upload flow appears high-risk or requires an architectural choice.
- Use `@fixer` for bounded implementation after API flow and files are known.
