# Handoff: Adaptive image scaling to reduce cropping

## Approved improvement

Implement **adaptive image scaling** so tall images are not aggressively cropped when the app window is resized wide.

User-described problem:

> when i resize the app to be wide, any image with a tall aspect ration gets a lot of area cut out at the top/bottom because the app scales images up to always fit the width of the window. how can we reduce the cropping unless its like a long comic strip that is not meant to be looked at in its entirety all at once

## Current goal

Implement features to reach feature parity with the official Reddit mobile app.

## Why this improvement

Wide desktop windows make width-fit media cards overly tall/cropped for portrait/tall images. The app should preserve visibility for normal/tall photos while still allowing long comics/infographics to be readable by width-fitting or opening in a scrollable/fullscreen viewer.

## Existing related implementation

Inspect these areas first:

- `lib/src/presentation/widgets/post_card.dart`
  - Feed card media rendering likely affected by wide-window cropping.
- `lib/src/presentation/widgets/media_viewer.dart`
  - Fullscreen media/gallery/video viewing. Existing project note says `VideoPlayer` must be wrapped in `AspectRatio` to avoid stretching; keep that intact.
- `lib/src/presentation/screens/post_detail_screen.dart`
  - Post detail media rendering may share or duplicate feed media layout behavior.
- Any media/image helper widgets under `lib/src/presentation/widgets/`.

Known project gotcha from `AGENTS.md`:

- `VideoPlayer` stretches by default; always wrap in `AspectRatio(aspectRatio: controller.value.aspectRatio)` for inline and fullscreen video. Do not regress this while changing image layout.

## Suggested behavior

Use adaptive layout by image aspect ratio and available viewport/card constraints:

- Normal images: prefer `BoxFit.contain` or an aspect-ratio-preserving layout so the whole image is visible.
- Tall-but-readable images: cap display height based on viewport/card height rather than always scaling to full window width.
- Very tall comic strips/infographics: treat as long media; allow width-fit with vertical scrolling/tap-to-open because containing the whole image would make text unreadably tiny.

Possible thresholds to tune after inspection:

- If `height / width <= 2.2`: show whole image, no crop.
- If `2.2 < height / width <= 4.0`: cap height and show a clear affordance to open fullscreen/full image.
- If `height / width > 4.0`: treat as long image/comic; width-fit in a constrained scrollable/fullscreen view or show a preview with “Tap to view full image”.

## Suggested implementation scope

Smallest useful vertical slice:

1. Identify the widget causing crop in feed/post detail media.
2. Centralize image sizing logic if currently duplicated.
3. Add adaptive sizing for image media using intrinsic aspect ratio when available.
4. For tall images, avoid top/bottom crop in inline cards by default.
5. For very long images/comics, keep readability by using preview + fullscreen/scroll behavior rather than shrinking the entire image into the card.
6. Ensure fullscreen media still supports zoom/pan and does not crop unexpectedly.

## UX requirements

- Wide windows should not make ordinary portrait images lose important top/bottom content.
- Long comics should remain readable, not shrunk to a tiny full-image preview.
- Users should have an obvious way to open the full image when inline display is constrained.
- Avoid layout jumps when image dimensions load asynchronously.
- Preserve existing video aspect-ratio behavior.

## Technical discovery needed

Before editing, inspect:

- How image dimensions/aspect ratio are represented in `Post` or media models.
- Current `Image`, `CachedNetworkImage`, `BoxFit`, `AspectRatio`, `ClipRect`, or `FittedBox` usage.
- Whether feed and post detail use the same media widget.
- Existing tests for media rendering, if any.
- Whether fullscreen viewer already handles long images well.

## Validation

Run after implementation:

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test` if tests are added/changed.
- Manual `flutter run` check on Windows desktop:
  - Resize app wide.
  - View a normal landscape image.
  - View a portrait/tall photo.
  - View a very tall comic/infographic.
  - Open each in fullscreen viewer.
  - Confirm video posts still preserve aspect ratio.

## Suggested skills / agents

- Use `@explorer` first if media rendering paths are unclear.
- Use `@designer` for visual/layout polish and responsive behavior.
- Use `@fixer` for bounded implementation once the affected media widgets are known.
- Use `@oracle` only if deciding a shared media layout architecture becomes ambiguous.
