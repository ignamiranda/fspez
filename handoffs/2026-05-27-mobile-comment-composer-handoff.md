# Mobile comment composer polish

## Problem

Commenting/reply is a high-frequency Reddit action, but the current composer is not optimized for mobile interaction:
- No bottom-sheet container — composer likely opens as a full-screen or inline widget rather than sliding up naturally from the bottom
- Lost text on accidental dismiss — closing the composer without sending discards the draft
- No parent-context preview — users writing a reply can't see what they're replying to without navigating away
- No markdown preview — users must guess how their formatting renders
- No keyboard-safe layout — the compose area and send button may be obscured by the soft keyboard
- No clear loading state during submission

## Scope

**Bottom-sheet composer** (`CommentComposerSheet` or similar):
- Slides up from the bottom as a draggable `DraggableScrollableSheet` or modal bottom sheet
- Large text input area with proper padding and clear send button
- Stays open and preserves draft text if the user accidentally dismisses (e.g., drag-down or tap outside)
- Explicit "Discard draft?" confirmation only if text was entered and not sent

**Parent-context preview:**
- Show a collapsed preview of the parent comment/post above the compose area
- Include author, truncated body (2–3 lines), and maybe upvote count
- Makes it easy to reference what you're replying to without switching screens
- Skip for top-level post comments where the post itself is already visible

**Markdown shortcuts & preview:**
- A row of inline formatting buttons: **bold**, *italic*, ~~strikethrough~~, [link](#), > quote, code block, or bullet list
- Tapping a button inserts the markdown syntax and places the cursor inside
- A preview toggle that switches the editor to a rendered markdown preview
- Uses existing markdown rendering (same as post/comment body rendering)

**Send flow:**
- Clear send button (icon + label) that's always visible and large enough for thumb reach
- Loading spinner on the send button while the API call is in flight
- Error state in-sheet (inline error message, not a dialog) with retry
- On success: close sheet cleanly, optionally show a brief snackbar, and refresh the comment thread

**Keyboard-safe layout:**
- `resizeToAvoidBottomInset` behavior — the sheet and input should not be hidden behind the keyboard
- Send button anchored at the bottom of the input area, not the screen bottom
- Sufficient bottom padding to account for the keyboard's "safe area"

**Reuse:**
- Use the same composer for:
  - Replying to a post (top-level comment)
  - Replying to a comment (nested reply)
  - Replying to an inbox message
  - Editing an existing comment (reuse edit sheet or augment)

## Out of scope

- Full rich-text editor (markdown preview toggle is sufficient)
- Draft persistence across sessions (handled by `local-drafts` handoff — this is draft-preservation only while the sheet is open)
- Image upload in comments
- Tagging users or communities with autocomplete

## Implementation notes

- Current comment flow lives in `lib/src/presentation/screens/post_detail_screen.dart` (comment actions/reply). Extract into a reusable widget.
- `lib/src/presentation/widgets/edit_sheet.dart` and `comment_tree.dart` are relevant for patterns.
- `RedditClient.comment()` posts to `POST /api/comment` — the existing implementation should be reused.
- Test the composer with both short replies and long formatted comments.
- Manual test: post detail → reply → type text → use markdown shortcuts → toggle preview → send → verify comment appears in thread.
