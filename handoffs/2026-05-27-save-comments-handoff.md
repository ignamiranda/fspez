# Save individual comments

## Scope
Add the ability to save/unsave individual comments (not just posts), with saved comments appearing in the existing Saved screen alongside saved posts.

## What to build
- Add save/unsave action to comment overflow menu (in `CommentTree` or wherever comment actions render)
- Wire to existing `SaveNotifier` — the save/unsave API (`POST /api/save`, `POST /api/unsave`) accepts a Reddit fullname (`id` param), and comments use the same fullname format (`t1_<id>` vs `t3_<id>` for posts). The existing notifier should work unchanged if it takes a `fullname`.
- Verify saved comments appear in the existing Saved listing screen — the `/saved` endpoint returns all saved things regardless of type, so they should already show up
- If Saved screen currently filters to posts only, broaden the filter to include comments

## Where to inspect
- `lib/src/presentation/widgets/comment_tree.dart` or `lib/src/presentation/widgets/post_card.dart` — comment actions area
- `lib/src/data/save_notifier.dart` or similar — confirm `fullname`-based save/unsave
- `lib/src/data/reddit_client.dart` — `save()` and `unsave()` method signatures
- `lib/src/presentation/screens/saved_screen.dart` or account/saved — verify comment rendering or filtering
- `lib/src/domain/models/post.dart` / `comment.dart` — comment model has `fullname` or `name` field

## Design notes
- Follow existing SaveNotifier semantics: revert + rethrow on error (per AGENTS.md)
- Visual feedback: icon toggle (filled bookmark / outline) with snackbar similar to post save
- In Saved screen, differentiate comments from posts visually (show parent post title, comment preview, link to context)
- Handle comment deleted/removed state if saved comment is later removed

## Non-goals
- Save collections or comment folders
- Cross-device save sync beyond Reddit's existing account-level save list

## Manual test steps
1. `flutter run`
2. Open any post with comments
3. Overflow on a comment — verify "Save" option appears
4. Save it — verify icon toggles, snackbar shows
5. Navigate to Account → Saved — verify the saved comment appears in the list with comment-specific formatting
6. Unsave from comment overflow — verify it disappears from Saved on next refresh
