# Swipe gestures on feed cards

## Scope
Add swipe-left / swipe-right gestures on feed post cards for quick actions (save, hide, upvote, downvote) with visual feedback, matching official Reddit mobile UX.

## What to build
- **Swipe right**: upvote (first swipe), downvote (second swipe, or swipe right from downvote state)
- **Swipe left**: save (first swipe), hide (second swipe), or configurable
- Visual feedback during gesture: colored background emerging from behind the card (orange for upvote, blue for downvote, green for save, red/gray for hide)
- Icon indicator following the swipe direction (arrow up/down, bookmark, eye-off)
- On release threshold: trigger the action; below threshold: snap back
- Haptic feedback on action trigger (use `HapticFeedback` from Flutter services)
- Must not conflict with existing scroll, tap, or long-press on cards
- Setting to enable/disable swipe gestures (in settings screen when it exists)

## Where to inspect
- `lib/src/presentation/widgets/feed_screen_scaffold.dart` — post list rendering with `ListView.builder` or similar
- `lib/src/presentation/widgets/post_card.dart` — individual card widget; may need to wrap in `Dismissible` or custom `GestureDetector`
- `lib/src/data/vote_notifier.dart` / `save_notifier.dart` / `hide_notifier.dart` — action APIs to call on gesture trigger

## Implementation notes
- Use `Dismissible` with `confirmDismiss` for left/right directional handling, OR custom `GestureDetector` + `AnimatedContainer` for more control over visual feedback
- Custom approach is preferred for better visual feedback (colored background, icon overlay, snap behavior)
- Swipe threshold: ~30-40% of card width
- On swipe during loading state: no-op or ignore
- Scroll conflict: use `HorizontalDragGestureRecognizer` with appropriate `gestureRecognizer` in `GestureDetector` to not interfere with vertical scroll
- Consider NestedScrollView or `ScrollView` integration carefully
- Cache gesture direction preferences optionally per-user later

## Non-goals
- Configurable action mapping for swipe directions (future — start with fixed sensible defaults)
- Swipe on comments (future — separate from feed cards)
- iOS-style haptics on Windows (use platform-appropriate feedback or graceful skip)

## Manual test steps
1. `flutter run`
2. Scroll through Home feed
3. Swipe right on a post card — verify upvote with orange background + arrow icon
4. Swipe right again — verify downvote (toggle)
5. Swipe left on next card — verify save with green background + bookmark icon
6. Swipe left again — verify hide with red/gray background + hide icon
7. Verify scroll still works normally (no gesture conflict)
8. Verify partial swipe snaps back without action
