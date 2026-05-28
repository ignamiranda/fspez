# Blocked users management

## Scope
Add a screen to view and manage blocked users, including unblock functionality, accessible from Account/Settings. Completes the block-unblock feature.

## What to build
- Create a "Blocked users" entry in Account screen or Settings screen
- Fetch blocked users list via Reddit API — verify endpoint: likely `/api/v1/me/blocked` or `/api/blocked` (or from `/api/v1/me/friends` with `?type=blocked`)
- Display blocked users in a list: username, blocked date (if available), avatar
- Unblock action: swipe or tap → confirm dialog → call unblock API
- Empty state: "No blocked users" message
- Handle pagination if blocked users exceed one page

## Where to inspect
- `lib/src/presentation/screens/account_screen.dart` — entry for blocked users list
- `lib/src/data/reddit_client.dart` — verify/find block/unblock API methods
- Existing block API: `POST /api/block` with `id` (fullname of user/thing to block) — verify via block-unblock handoff findings
- Unblock API may be: `POST /api/unfriend` with `type=enemy` and `id` (user fullname)
- `lib/src/domain/models/user.dart` — user model for blocked user display

## Implementation notes
- Blocked users list endpoint needs verification — check if `GET /api/v1/me/blocked` works with cookie auth, or if `GET /api/blocked` is the correct path
- Fallback: store blocked users locally in SharedPreferences (less ideal but works if API list endpoint is unavailable)
- Each blocked user item shows: username, avatar (if available), unblock button
- Unblock: confirm dialog "Unblock @username? They will be able to see your content and send you messages."
- Handle deleted/suspended blocked users (show "[deleted]" or similar)
- Refresh the list after unblock

## Dependencies
- block-unblock handoff implementation (confirms working block/unblock API endpoints)

## Non-goals
- Blocking from this screen (block is done from user profiles/posts — this is management only)
- Bulk unblock
- Per-block reason or notes

## Manual test steps
1. `flutter run`
2. Have at least one blocked user (block from a profile or post)
3. Navigate to Account → Blocked users
4. Verify blocked user appears in list with username
5. Tap unblock → confirm dialog → verify user removed from list
6. Verify the unblocked user can now interact normally
7. Test with no blocked users — verify "No blocked users" empty state
