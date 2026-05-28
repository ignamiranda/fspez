# Multireddit navigation

## Scope
Add multireddit support: fetch user's multireddits and provide a way to navigate/view them, matching official Reddit mobile.

## What to build
- Fetch user's multireddits via `/api/multi/mine` or `/api/v1/me/multireddits` (verify correct endpoint)
- Display multireddits in a navigable surface — a sidebar/drawer, a bottom sheet from the feed filter, or a dedicated screen accessible from Account
- Each multireddit entry shows: name, description (if short), subreddit count, optionally icon/path
- Tap opens the multireddit feed: URL format `/r/{sub1}+{sub2}+...` or use `/api/multi/user/{user}/m/{multiname}` JSON endpoint
- Display multireddit feed in existing feed infrastructure (reuse `SubredditFeedScreen` or `FeedScreen`)
- Handle empty multireddits (user has none)
- Handle deleted/private multireddits gracefully

## Where to inspect
- `lib/src/presentation/screens/feed_screen.dart` — current feed entry point; consider adding multireddit as a feed source
- `lib/src/data/reddit_client.dart` — check if multi endpoint is already implemented
- `lib/src/data/feed_pagination.dart` — feed loading; multireddit feeds use the same subreddit-style `/r/name.json` URL pattern
- `lib/src/presentation/screens/account_screen.dart` — possible entry point for multireddit management

## Implementation notes
- Multireddit feed URL format: `/r/{name1}+{name2}+.../{sort}.json`
- Multireddit paths from API: `/user/{username}/m/{multiname}`
- The existing feed pagination infrastructure should work with subreddit-style URLs
- Display name: use `display_name` or `name` from the multi API response
- Caching multireddits locally is optional but nice (don't fetch on every feed open)
- Public multireddits from other users: lower priority, focus on own multireddits first

## Non-goals
- Create/edit/delete multireddits (read-only navigation first)
- Public multireddit discovery (browse trending multis)
- Multireddit icons/avatars (future)
- Subreddit management within multireddits (add/remove subreddits)

## Manual test steps
1. `flutter run` with an account that has multireddits
2. Navigate to Account screen or feed selector — verify multireddit entry
3. Open multireddit list — verify name, subreddit count shown
4. Tap a multireddit — verify feed loads with combined subreddit posts
5. Verify sort (hot/new/top) works in multireddit feed
6. Verify refresh and pagination work
7. Test with account that has no multireddits — verify empty state
