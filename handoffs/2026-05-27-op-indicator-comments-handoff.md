# OP indicator on comments

## Scope
Show a blue "OP" tag next to comments made by the original poster in a thread, matching official Reddit mobile UX.

## What to build
- In `CommentTree`, compare each comment's author with the post's author (`widget.post.author` or via provider)
- If they match, render a small "OP" chip/badge next to the author name
- Styling: blue background with white text, small pill/chip shape, ~16-18px height, matching Reddit mobile style
- The post author info is already available in `PostDetailScreen` — it needs to flow into `CommentTree` and `CommentWidget`

## Where to inspect
- `lib/src/presentation/widgets/comment_tree.dart` — comment rendering, author name display area
- `lib/src/presentation/screens/post_detail_screen.dart` — where `CommentTree` is instantiated, post author available
- Search for `author` or `subreddit` display patterns in comment widgets

## Implementation notes
- Pass `postAuthor` (or fullname) down to `CommentTree` as a parameter
- Very cheap: one string comparison per top-level comment (replies compare same author)
- Handle deleted/unknown authors gracefully (no OP tag for `[deleted]`)
- If `CommentTree` renders recursively for nested replies, pass `postAuthor` through the recursion

## Non-goals
- Moderator/Admin distinguished tags (future)
- "OP" on inbox messages (less relevant — author context is a different thread)

## Manual test steps
1. `flutter run`
2. Open any post
3. Find a comment by the original poster — verify blue "OP" tag next to their name
4. Verify other comments lack the tag
5. Check a deleted OP comment (author `[deleted]`) — no OP tag
6. Nested replies from OP — verify OP tag also appears on their replies
