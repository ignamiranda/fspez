# Delete inbox messages

## Scope
Allow users to delete conversations and individual messages from their inbox, matching official Reddit mobile capability.

## What to build
- Add delete action to message/thread in `InboxScreen` (overflow menu or swipe action)
- Confirmation dialog before deletion ("Delete this message/conversation?")
- Call Reddit API to delete message(s) — verify correct endpoint (`POST /api/del_msg` or `POST /api/del` with fullname)
- Remove deleted messages from local state/UI optimistically
- Handle message vs conversation deletion (delete single message vs entire thread)

## Where to inspect
- `lib/src/presentation/screens/inbox_screen.dart` — message list and action buttons
- `lib/src/data/inbox_repository.dart` — data layer; check if delete method exists or needs to be added
- `lib/src/data/reddit_client.dart` — check for existing `delete` endpoint support (used for post/comment deletion)
- `lib/src/domain/models/message.dart` — message model has `fullname` or `name` field

## Implementation notes
- Reddit inbox delete endpoint may be: `POST /api/del_msg` with `id` = message fullname (`t4_xxxxx`)
- Or use `POST /api/del` if it accepts message fullnames (same as post/comment deletion)
- Verify endpoint works with cookie-only auth before building UI
- Confirm dialog: "Delete message?" / "This will remove this message from your inbox. This action cannot be undone."
- Optimistic removal from local list; revert on API error
- Delete vs block: keep separate (block user vs delete message)

## Non-goals
- Bulk delete / "Delete all" messages (future)
- Archive messages (Reddit doesn't have archive; delete is the cleanup action)
- "Mark all read" (separate feature)

## Manual test steps
1. `flutter run`
2. Navigate to Inbox
3. Open a message thread
4. Tap overflow → "Delete"
5. Verify confirmation dialog appears
6. Confirm deletion
7. Verify message disappears from inbox
8. Refresh inbox — verify message is gone (server-side deletion confirmed)
9. Test cancel from confirmation dialog — verify message remains
10. Test with network error — verify message reappears on failure
