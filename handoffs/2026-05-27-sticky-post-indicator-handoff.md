# Sticky/pinned post indicator

## Scope
Show a visual pinned/sticky indicator on stickied posts in subreddit feeds and post detail, matching official Reddit mobile UX.

## What to build
- Parse the `stickied` boolean field from post API data (likely already flows through response parsing)
- In `PostCard`, when `post.stickied == true`, show a green pin 📌 icon or "Pinned" label near the post metadata (subreddit name or timestamp area)
- In `PostDetailScreen`, also show the stickied indicator in the post header
- Styling: small green pin icon + "Pinned" text, or a colored chip/badge
- Only show on subreddit feeds (r/subredditname) — not on Home/Popular/All aggregate feeds where stickied posts behave differently

## Where to inspect
- `lib/src/presentation/widgets/post_card.dart` — post metadata row (subreddit name, timestamp, etc.)
- `lib/src/presentation/screens/post_detail_screen.dart` — post header
- `lib/src/domain/models/post.dart` — confirm `stickied` field is parsed
- `lib/src/data/api_responses.dart` — JSON mapping for `stickied`

## Implementation notes
- The `stickied` field is a boolean in Reddit API responses and likely already mapped in the Post model
- Show only in subreddit feeds (check if the feed context has a subreddit, or always show in subreddit feed)
- Pin icon: use `Icons.push_pin` or a small custom painted pin widget (green color)
- Handle null/undefined `stickied` gracefully (treat as not stickied)

## Non-goals
- Distinguishing between moderator sticky vs admin sticky (differentiated field not commonly used)
- Distinguishing between stickied post vs collection/curated post
- Sort-order awareness (stickied posts appear at top regardless of sort — this is server-side behavior)

## Manual test steps
1. `flutter run`
2. Navigate to a subreddit that has pinned posts (e.g. r/announcements, most mod-run subreddits)
3. Verify pinned posts show a green pin icon or "Pinned" label
4. Tap into a pinned post — verify indicator shows in post detail as well
5. Verify Home/Popular/All feeds do NOT show pinned indicators (or show if Reddit API returns them — verify behavior)
6. Verify non-stickied posts have no indicator
