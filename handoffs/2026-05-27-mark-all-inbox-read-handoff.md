# Mark all inbox as read

## Scope
Add a single-action "Mark all as read" button to the inbox, clearing the unread badge for all messages at once, matching official Reddit mobile UX.

## What to build
- Add a "Mark all as read" action button in the inbox app bar or overflow menu (in addition to the existing per-message mark-as-read)
- On tap: confirm dialog or immediate action (opinionated: immediate is fine since it's reversible via Reddit's read history)
- Call Reddit API to mark all messages as read — verify endpoint (`POST /api/read_all_messages` or similar)
- Update local unread count to 0
- Update all displayed messages to "read" visual state (remove bold/dot styling)

## Where to inspect
- `lib/src/presentation/screens/inbox_screen.dart` — inbox app bar and actions
- `lib/src/data/inbox_repository.dart` — existing `markAsRead()` method; check if bulk endpoint differs
- `lib/src/data/inbox_notifier.dart` — state management for unread count and message states
- `lib/src/data/reddit_client.dart` — check for existing bulk read endpoint

## Implementation notes
- Reddit endpoint: `POST /api/read_all_messages` with no parameters (marks all as read)
- Or iterate fullnames with existing `POST /api/read_message` per message — less efficient but works
- Prefer the bulk endpoint if it exists and works with cookie auth
- Optimistic update: immediately clear unread count, revert on API error
- Show snackbar feedback: "All messages marked as read" / "Failed to mark all as read"
- Only show when there are unread messages (don't show if count is 0)

## Non-goals
- "Mark as unread" for individual or bulk messages (future)
- Archive all (Reddit doesn't have archive)
- Select-multiple messages for batch operations (future)

## Manual test steps
1. `flutter run`
2. Navigate to Inbox with unread messages
3. Tap "Mark all as read" button (overflow menu or app bar)
4. Verify unread badge disappears
5. Verify all messages appear as read (no bold/dot)
6. Refresh inbox — verify changes persisted server-side
7. Test with zero unread — verify button not shown
8. Test with network error — verify badge/messages revert to unread
