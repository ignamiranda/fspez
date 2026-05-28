# Auto-play muted videos in feed

## Scope
Videos in the feed start playing automatically (muted) when they scroll into view, and pause when scrolled off, matching official Reddit mobile UX.

## What to build
- Detect when a video post's card enters the visible viewport while scrolling
- When visible: start playing the video (muted) if not already playing
- When scrolled out of view: pause and reset (or pause-in-place)
- Only auto-play one video at a time (the most visible one) to avoid performance issues
- Show a muted speaker icon overlay (user can tap to unmute)
- Show a play/pause overlay on tap
- Respect existing media viewer fullscreen behavior (tap opens fullscreen viewer)

## Where to inspect
- `lib/src/presentation/widgets/post_card.dart` — media rendering area, where video thumbnail/player is shown
- `lib/src/presentation/widgets/media_viewer.dart` — existing video player setup
- `lib/src/presentation/widgets/feed_screen_scaffold.dart` — scroll view for detecting visibility
- Look for `VideoPlayerController` or `video_player` usage in the feed context

## Implementation notes
- Use `ScrollController` + `Listener` or `VisibilityDetector` package to detect card visibility
- Track which card is the primary visible video — only auto-play one at a time
- `VideoPlayerController` with `controller.setVolume(0)` for muted playback
- Mute/unmute toggle: speaker icon overlay, tapping calls `controller.setVolume(1.0)` / `setVolume(0.0)`
- Handle scroll performance: use a threshold (e.g. 60% of card visible) before starting playback
- Dispose controllers when cards scroll far away or are recycled
- Consider `AutomaticKeepAliveClientMixin` or similar to prevent video cards from being disposed when partially visible
- Respect existing `AspectRatio` wrapping for video (AGENTS.md gotcha)

## Non-goals
- Audio playback in feed (always start muted — user taps to unmute)
- Auto-advance to next video (playlist-style)
- Pre-buffering off-screen videos (performance concern)
- GIF auto-play (already handled differently or not applicable)
- Settings toggle for auto-play behavior (future — can be added to settings screen)

## Manual test steps
1. `flutter run`
2. Browse a feed with video posts
3. Scroll down — verify video starts playing muted when mostly visible
4. Scroll past — verify video pauses/stops
5. Scroll back up — verify video resumes playing
6. Tap mute icon on playing video — verify audio unmutes
7. Tap mute icon again — verify audio mutes
8. Tap video — verify either opens fullscreen viewer or toggles play/pause
9. Verify only one video plays at a time
