# Live comment updates

## Scope
Add periodic polling for new comments on the post detail screen, showing a "X new comments" banner with tap-to-load, matching official Reddit mobile UX.

## What to build
- After opening a post detail, start a periodic timer (every 15-30 seconds) that fetches new comments via the Reddit API with an `after`/`before` parameter or `?sort=new` to get recent comments
- When new comments are found, show a banner/pill at the top of the comment list: "X new comments" with an arrow
- Tap the banner → insert new comments at the top of the list (above existing loaded comments)
- The polling stops when the user navigates away from the post detail screen
- Low polling frequency and small data transfer (just comment IDs/new since last check)

## Where to inspect
- `lib/src/presentation/screens/post_detail_screen.dart` — comment list and loading
- `lib/src/data/comment_repository.dart` or comment data layer — check how comments are fetched
- `lib/src/data/feed_pagination.dart` — pagination patterns that could be reused for incremental comment loading
- `lib/src/data/reddit_client.dart` — comment fetch endpoint

## Implementation notes
- Use `Timer.periodic` that starts on `initState` (or when post detail is ready) and cancels on `dispose`
- Fetch comment tree with `?sort=new&limit=5` to get only the latest ones
- Compare with current comment IDs to find genuinely new comments
- Show banner with count: `Icon(Icons.arrow_downward) "3 new comments"` with tappable `InkWell`
- After polling, keep the most recent comments and continue from there
- Handle no-new-comments gracefully (silent poll, no banner)
- Handle network errors silently (don't show error for polling failures)
- Stop polling if user switches to a different sort order (or restart with new sort)

## Non-goals
- Real-time push notifications for new comments (WebSocket/SSE — not supported by Reddit)
- "Live" auto-loading without user action (official app also requires tap to load)
- Background polling when app is minimized

## Manual test steps
1. `flutter run`
2. Open an active post with frequent new comments (or test with two windows — leave post open in app, add comment via browser)
3. Wait — verify "X new comments" banner appears
4. Tap banner — verify new comments load into the existing list
5. Tap again after more comments appear — verify second batch loads
6. Navigate away and back — verify polling restarts
7. Open a post with no new activity — verify no banner shown, no errors
