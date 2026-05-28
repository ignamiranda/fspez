# Search within subreddit

## Scope
Add the ability to search only the current subreddit from `SubredditFeedScreen`, matching official Reddit mobile UX.

## What to build
- Add a search bar or search icon button to `SubredditFeedScreen` (app bar or below header)
- When tapped, navigate to or overlay search with subreddit-scoped query
- Use Reddit search API with `restrict_sr=on` or `&subreddit={name}` parameter to scope results to the current subreddit
- Display results in existing search result UI (reuse `SearchScreen` or a dedicated results panel)
- Show a visual indicator that search is scoped ("Search in r/subredditname")
- Option to clear scope and search all of Reddit

## Where to inspect
- `lib/src/presentation/screens/subreddit_feed_screen.dart` — app bar and layout
- `lib/src/presentation/screens/search_screen.dart` — existing search infrastructure
- `lib/src/data/reddit_client.dart` — search API method, check if `restrict_sr` parameter is supported

## Implementation notes
- Reuse existing `SearchNotifier`/search providers if possible — add optional `subreddit` parameter
- If `restrict_sr=on` works, this is very cheap to implement; test it first
- Keep search results within the subreddit context (don't navigate to a separate "all Reddit" experience unless user clears scope)
- Handle empty subreddit (shouldn't happen) and deleted subreddit gracefully

## Non-goals
- Search within comments of a subreddit
- Search within saved/hidden lists (future)
- Persistent search history per subreddit

## Manual test steps
1. `flutter run`
2. Navigate to any subreddit (e.g. r/FlutterDev)
3. Tap search icon/bar
4. Type a query relevant to that subreddit
5. Verify results are scoped to that subreddit only
6. Clear scope — verify search returns to global results
7. Verify indicator shows "Search in r/FlutterDev"
