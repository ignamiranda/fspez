# Relative timestamps

## Scope
Replace absolute date/time strings with relative timestamps ("2h ago", "3d ago", "1w ago") across the app, matching official Reddit mobile UX.

## What to build
- A `RelativeTime` helper/extensions class that converts a `DateTime` to a human-readable relative string:
  - `<1 min`: "just now"
  - `1-59 min`: "Xm ago"
  - `1-23 hours`: "Xh ago"
  - `1-6 days`: "Xd ago"
  - `7-30 days`: "Xw ago"
  - `>30 days`: "Xmo ago" or "Xyr ago"
- Apply to all visible timestamps:
  - `PostCard` — post created time in feed
  - `CommentTree` — comment timestamps
  - `InboxScreen` — message timestamps
  - `PostDetailScreen` — post timestamp in header
  - `UserProfileScreen` — account age (already a duration format, but consistent)
- Optionally: show full absolute date on hover/tap (tooltip or `Tooltip` widget)

## Where to inspect
- `lib/src/presentation/widgets/post_card.dart` — post time rendering
- `lib/src/presentation/widgets/comment_tree.dart` — comment time rendering
- `lib/src/presentation/screens/inbox_screen.dart` — message time rendering
- `lib/src/presentation/screens/post_detail_screen.dart` — post header time
- Search for `DateTime` formatting or `timeAgo`/`time` display patterns across widgets

## Implementation notes
- Pure display change — no API or data model changes needed
- Create a shared utility function/extension: `extension DateTimeX on DateTime { String get relative; }` in a utility file
- Consider auto-updating timestamps (e.g. `Timer` every 60s) — optional, can start static and add live updates later
- Test with edge cases: future timestamps (shouldn't happen), very old posts, null timestamps
- Keep existing absolute format as fallback/tooltip

## Non-goals
- Configurable date format preferences (future if settings infrastructure exists)
- Live ticking timestamps (nice-to-have, can be added later)

## Manual test steps
1. `flutter run`
2. Browse Home feed — verify timestamps show as "2h ago", "3d ago", etc.
3. Open a post — verify comment timestamps show relatively
4. Open inbox — verify message timestamps show relatively
5. Check a post from a week ago — verify "1w ago" or "7d ago"
6. Hover/tap a timestamp — verify full date tooltip appears (if implemented)
