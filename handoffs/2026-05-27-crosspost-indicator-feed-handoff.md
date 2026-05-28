# Crosspost indicator in feed

## Scope
Show a visual crosspost label/badge on crossposted posts in the feed, matching official Reddit mobile UX.

## What to build
- Parse `crosspost_parent` and `crosspost_parent_list` fields from post API response (may already be partially parsed)
- In `PostCard`, when the post is a crosspost (`crosspost_parent != null`), show a small pill/chip: "r/OriginalSubreddit" or "Crossposted from r/..." near the post metadata
- The original post data may be available in `crosspost_parent_list[0]` which contains the full original post object
- Tap on crosspost label could navigate to the original post (nice-to-have)

## Where to inspect
- `lib/src/presentation/widgets/post_card.dart` — post metadata rendering
- `lib/src/domain/models/post.dart` — check if `crosspostParent`, `crosspostParentList` are parsed
- `lib/src/data/api_responses.dart` — JSON mapping for `crosspost_parent` and `crosspost_parent_list` fields
- `lib/src/presentation/screens/post_detail_screen.dart` — crosspost handling in detail view

## Implementation notes
- `crosspost_parent` is a fullname like `t3_abc123` indicating the original post
- `crosspost_parent_list` contains the parsed original post data (same structure as a regular post)
- Show "Crossposted from r/originalname" with the original subreddit name
- If original post is deleted/removed, show generic "Crossposted post" without subreddit link
- Style: small subdued text or pill, similar to pinned indicator style

## Non-goals
- Crosspost creation (covered by crosspost-creation-handoff)
- Showing original post content inline in feed (tap to open)
- Crosspost analytics (view counts from original)

## Manual test steps
1. `flutter run`
2. Browse feed for crossposted posts (common in r/popular, r/all)
3. Verify "Crossposted from r/subreddit" label appears on crosspost cards
4. Tap the post — verify post detail shows crosspost info (if implemented)
5. If no crossposts in feed, search for a known crossposted post
