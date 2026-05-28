# Subreddit icon/avatar display in feed cards

## Scope
Display each post's subreddit icon/avatar next to the community name on post cards in the feed, matching official Reddit mobile UI.

## What to build
- Parse and display `sr_detail.icon_img` from post API data (this field likely already flows through existing response parsing)
- Small (~20×20) circular `CircleAvatar` or `ClipOval` widget left of `r/subredditname` in `PostCard`
- Apply URL cleaning (`&amp;` → `&`) via established `_cleanUrl()` pattern — see AGENTS.md "Reddit URL entity encoding" gotcha
- Graceful fallback: render nothing (no broken image/placeholder) when icon is missing, empty, or fails to load via `Image.network` errorBuilder
- Optional parallel: add icon to `SubredditFeedScreen` header as well

## Where to inspect
- `lib/src/presentation/widgets/post_card.dart` — subreddit name rendering area
- `lib/src/presentation/screens/subreddit_feed_screen.dart` — header icon (optional)
- `lib/src/domain/models/post.dart` and `api_responses.dart` — confirm `sr_detail.icon_img` is parsed

## Implementation notes
- Use `_cleanUrl()` helper pattern from the existing codebase before passing to `Image.network`
- `Image.network` errorBuilder: return `SizedBox.shrink()` on load failure
- Cache handled by Flutter image cache; no special caching needed
- Subreddit feed header icon is nice-to-have but optional for this handoff

## Non-goals
- Subreddit banner images or full sr_info display
- Non-feed icon display (inbox, search results, post detail) — future scope
- Precaching or prefetching subreddit icons
- Placeholder/fallback icon (subreddit default snoo) — graceful empty is sufficient

## Manual test steps
1. `flutter run`
2. Browse Home feed — verify subreddit circular icons appear next to `r/...` text on post cards
3. Browse Popular and All — verify same
4. Find a subreddit with no icon — verify no broken image or placeholder
5. Verify icons are ~20×20 circular, well-aligned with text
