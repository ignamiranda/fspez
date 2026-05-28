# Image upload in comments/replies

## Scope
Allow users to upload and attach images inline when commenting or replying, matching official Reddit mobile UX.

## What to build
- Add an image/gallery attachment button to the comment composer (bottom-sheet composer from `mobile-comment-composer-handoff` or existing reply UI)
- On tap: open file/image picker (media post submission handoff will establish the picker)
- Upload the selected image to Reddit's media upload endpoint (`POST /api/upload_media` or similar)
- Insert the returned markdown image reference (`[text](url)` or `![]()` ) into the comment text at cursor position
- Show attached image thumbnail in the composer before submission
- Support removing attached images before submitting
- Support multiple image attachments if Reddit API allows (gallery-style comments)
- The comment text + image markdown is submitted as a single comment via the existing comment API

## Dependencies
- Media/image picker should be established by `media-post-submission-handoff` first (or use a direct file picker)
- Comment composer bottom sheet from `mobile-comment-composer-handoff`

## Where to inspect
- `lib/src/data/reddit_client.dart` — check if media upload endpoint (`/api/upload_media`) exists
- `lib/src/presentation/screens/post_detail_screen.dart` — current comment reply flow
- Media post submission code (when available) — the same upload endpoint

## Implementation notes
- Reddit media upload endpoint returns a JSON with `url` or `errors` — see media-post-submission investigation
- Image markdown in comments: `[](url)` format with optional caption text
- Maximum image size/count follows Reddit's limits (typically <20MB per image)
- Handle upload progress/loading state in composer
- Handle upload failure: show error, don't clear composed text
- Compress/size images if practical before upload

## Non-goals
- Video upload in comments (not supported by Reddit)
- Inline text formatting toolbar for comments (markdown preview is separate)
- Image upload in direct messages (future)

## Manual test steps
1. `flutter run`
2. Open any post
3. Tap reply/comment
4. Tap image attachment button
5. Select an image from the picker
6. Verify thumbnail appears in composer
7. Add comment text and submit
8. Verify comment appears with image inline
9. Test removing attached image before submitting
10. Test upload failure (network off) — verify error message and text preserved
