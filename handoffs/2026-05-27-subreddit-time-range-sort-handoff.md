# Subreddit post time-range sort

## Scope
Add time range filtering for Top-sorted feeds in subreddits and home/popular, matching official Reddit mobile time range selector.

## What to build
- When sort is set to Top, show a time range chips/pill selector: Now / Today / This Week / This Month / This Year / All Time
- Reddit API `t=` parameter: `hour`, `day`, `week`, `month`, `year`, `all`
- Tap a time range → reload feed with that time range
- Visual indicator of active time range (highlighted/filled chip)
- Persist last selected time range per sort mode if straightforward (optional)

## Where to inspect
- `lib/src/presentation/screens/feed_screen.dart` — feed sort bar/selector
- `lib/src/presentation/screens/subreddit_feed_screen.dart` — subreddit sort selector
- `lib/src/data/feed_pagination.dart` — sort parameter handling, likely `CursorPaginatedNotifier` or `FeedPageNotifier`
- `lib/src/data/reddit_client.dart` — feed fetch method, check if `t=` param already supported

## Design notes
- Time range chips should appear horizontally scrollable if many, below the sort selector
- Only show when current sort is Top (all other sorts ignore time range)
- Default to "All Time" or "Today" — match Reddit mobile default
- Changing sort away from Top should auto-hide the time range chips
- Applies to Home, Popular, All, and subreddit feeds consistently

## Non-goals
- Time range for search results (different API parameter)
- Custom date range picker (Reddit only supports preset ranges)
- Time range for Controversial sort (Reddit supports it but lower priority)

## Manual test steps
1. `flutter run`
2. Navigate to any feed (Home, subreddit, Popular)
3. Tap sort selector → choose "Top"
4. Verify time range chips appear below sort bar
5. Tap "Today" — feed reloads with today's top posts
6. Tap "This Week" — feed reloads
7. Tap "All Time" — feed reloads
8. Change sort away from Top — verify chips disappear
9. Return to Top — verify chips reappear
