# Handoff: Local drafts for posts, comments, replies, and messages

## Approved feature

Implement **local drafts** for unfinished posts, comments, replies, and direct messages.

## Current goal

Implement features to reach feature parity with the official Reddit mobile app.

## Why this feature

The official Reddit app preserves unfinished writing flows so users can leave and resume later. This app has post submit, comment reply, inbox reply, and direct-message compose flows, but no draft persistence was identified in the feature inventory.

## Existing related implementation

Inspect these areas first:

- `lib/src/presentation/screens/submit_screen.dart`
  - Text/link post submission form.
- `lib/src/presentation/screens/post_detail_screen.dart`
  - Comment/reply entry points and post detail refresh behavior.
- `lib/src/presentation/widgets/comment_tree.dart`
  - Comment reply UI entry points.
- `lib/src/presentation/screens/compose_screen.dart`
  - Direct message compose form.
- `lib/src/presentation/screens/inbox_screen.dart`
  - Inbox reply flows and message thread expansion.
- `lib/main.dart`
  - `SharedPreferences` initialization/override pattern.
- `lib/src/data/`
  - Existing Riverpod notifiers/providers and persistence conventions.

Already implemented features to avoid re-suggesting as new work:

- Feed browsing/sorting/refresh/pagination.
- Post interactions: vote/save/hide/delete/edit body/open links.
- Post detail/comments/replies/media/link display.
- Search posts/communities/comments/media/profiles.
- Subreddit view subscribe/unsubscribe/submit.
- User profiles.
- Inbox All/Unread/Sent with message threads/reply/compose.
- Direct message compose.
- Text/link post submit.
- Account multi-account add/remove/switch/logout.
- Saved/hidden/history screens.
- WebView auth.
- Fullscreen media viewer/gallery/video.
- Basic comment collapse/expand.

Related approved handoffs:

- `handoffs/2026-05-27-in-app-settings-screen-handoff.md`
- `handoffs/2026-05-27-read-posts-history-sync-handoff.md`
- `handoffs/2026-05-27-edit-post-remaining-gaps-handoff.md`

## Suggested implementation scope

Smallest useful vertical slice:

1. Add a local draft store keyed by draft context.
   - Post submit draft: subreddit + kind + title/body/url fields.
   - Comment/reply draft: parent thing fullname or post/comment context.
   - Message draft: recipient + subject/body or reply context.
2. Persist draft text locally as the user types, debounced if useful.
3. Restore existing draft when reopening the same compose context.
4. Prompt before discarding non-empty unsent text when leaving a compose flow.
5. Clear the draft after successful submission/send.
6. Add simple draft management only if a natural entry point exists; otherwise defer a full drafts screen.

## Technical discovery needed

Before editing, inspect:

- Whether forms already use controllers that can be wired to persistence safely.
- How navigation pop/back handling is implemented in current screens.
- Whether `SharedPreferences` is enough for small local drafts, or whether a small JSON map abstraction should wrap it.
- How multi-account switching should affect drafts.
  - Recommended default: include account username/session identity in the draft key if available so drafts do not bleed across accounts.
- Whether edit sheets should use draft behavior separately from new comments/posts.
  - Editing failure preservation is already covered by `edit-post-remaining-gaps`; avoid duplicating that work unless shared infrastructure is natural.

## UX requirements

- Draft restore should not surprise users by silently sending stale content.
- If restoring a draft, make the restored content visible immediately.
- Leaving a form with unsent non-empty content should ask whether to discard or keep draft.
- Successful submit/send should remove that draft.
- Failed submit/send should keep the draft.
- Keep labels clear: “Draft saved”, “Discard draft”, “Continue editing”.

## Deferred out of scope

- Reddit/server-side draft sync unless endpoint support is verified.
- Full drafts inbox/manager unless cheap after the draft store exists.
- Rich media upload drafts; media post submission has its own handoff.
- Scheduled posts.
- Auto-saving sensitive auth/session data; drafts should contain only user-entered compose content and context keys.

## Validation

Run after implementation:

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test` if tests are added/changed.
- Manual `flutter run` checks:
  - Start a text post, leave, reopen, confirm draft restores.
  - Submit successfully and confirm draft clears.
  - Start a comment reply, leave, reopen same reply context, confirm draft restores.
  - Start a direct message, leave, reopen, confirm draft restores.
  - Switch accounts if practical and confirm drafts do not bleed between users.

## Suggested agents

- Reuse explorer session `exp-2 Check post edit implementation` for submit/comment/post-detail context if more discovery is needed.
- Use `@fixer` for bounded implementation once draft keying and persistence approach are chosen.
- Use `@designer` if discard/restore prompts need UI polish.
- Use `@oracle` only if draft ownership, multi-account isolation, or persistence shape becomes ambiguous.
