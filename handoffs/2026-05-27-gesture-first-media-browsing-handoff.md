# Handoff: Gesture-first mobile media browsing

## Approved mobile UX improvement

Improve fullscreen media browsing so it feels like a native mobile Reddit experience: gesture-first, smooth, and forgiving.

## Current goal

Implement features to reach feature parity with the official Reddit mobile app, prioritizing mobile-app parity and mobile-quality UX.

## Why this improvement

Reddit mobile users expect media viewing to be fast and touch-native. This app already has fullscreen media/gallery/video support, but this handoff focuses on polish: swipe gestures, zoom behavior, drag-to-dismiss, transitions, and mobile-friendly controls.

## Existing related implementation

Inspect these areas first:

- `lib/src/presentation/widgets/media_viewer.dart`
  - Existing fullscreen media viewer, gallery swipe, zoom, video support.
- `lib/src/presentation/widgets/post_card.dart`
  - Inline media preview tap/open behavior.
- `lib/src/presentation/screens/post_detail_screen.dart`
  - Media/link viewing from detail screen.
- Any image/video helper widgets used by post cards or detail pages.

Known project gotcha:

- `VideoPlayer` stretches by default. Always preserve aspect ratio with `AspectRatio(aspectRatio: controller.value.aspectRatio)` for inline and fullscreen video.

Related approved handoffs:

- `handoffs/2026-05-27-adaptive-image-scaling-handoff.md`
- `handoffs/2026-05-27-offline-cache-stale-while-revalidate-handoff.md`

## Suggested implementation scope

Smallest useful vertical slice:

1. Audit current fullscreen media gestures and identify gaps.
2. Ensure galleries support natural horizontal swipe between items.
3. Add or refine pinch-to-zoom for images.
4. Add double-tap zoom toggle for images.
5. Add drag-down-to-dismiss when media is not zoomed in.
6. Ensure controls fade/hide in a mobile-friendly way and remain discoverable.
7. Preserve video aspect ratio and avoid accidental gesture conflicts with video controls.

## Gesture behavior requirements

- Horizontal swipe changes gallery item when not zoomed in.
- Pinch zoom should not accidentally page the gallery.
- Double tap should zoom into the tapped region if practical; otherwise center zoom is acceptable.
- Drag down should dismiss only when image scale is at or near default.
- Tap should toggle chrome/controls where appropriate.
- Back gesture/system back should dismiss fullscreen media cleanly.

## UX requirements

- Keep media controls large enough for touch.
- Avoid tiny desktop-style hover-only affordances.
- Loading/error states should be legible over dark fullscreen background.
- For long images/comics, coordinate with the adaptive image scaling handoff: do not force the whole image into one cropped viewport.
- Animations should be smooth but not overbuilt.

## Technical discovery needed

Before editing, inspect:

- Whether `InteractiveViewer`, `PageView`, or custom gesture detectors are currently used.
- Existing media viewer state model and how it tracks current gallery index.
- Whether videos and images share gesture layers that may conflict.
- Current desktop/window assumptions that should be adjusted for mobile-first behavior.
- Testability of gesture changes with widget tests.

## Deferred out of scope

- Download/save media to device.
- Media sharing; covered separately by share/copy handoff.
- Full TikTok/Reels-style vertical video feed.
- Advanced image editor or annotations.
- Platform-specific native gallery integrations.

## Acceptance criteria

- Fullscreen image media supports pinch zoom and double-tap zoom.
- Gallery swiping remains reliable.
- Drag-down dismiss works when media is not zoomed.
- Video playback preserves aspect ratio and controls remain usable.
- Gestures do not fight each other in common scenarios.
- Existing gallery/video functionality does not regress.

## Validation

Run after implementation:

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test` if tests are added/changed.
- Manual `flutter run` checks, preferably on a touch-capable device/emulator if available:
  - Open image fullscreen; pinch zoom, double tap, pan, drag down dismiss.
  - Open gallery; swipe between items, zoom one item, confirm gallery paging is not accidental while zoomed.
  - Open video; confirm aspect ratio and controls remain usable.
  - Open a tall image/comic and confirm it does not crop unexpectedly.

## Suggested skills / agents

- Use `@designer` for gesture/interaction polish if implementing directly.
- Reuse explorer session `exp-2 Check post edit implementation` if more media viewer context is needed.
- Use `@fixer` for bounded implementation once gesture behavior and widget boundaries are clear.
- Use `@oracle` only if gesture architecture becomes tangled enough to require redesign.
