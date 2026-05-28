# Gallery/multi-image post indicator in feed

## Scope
Show a gallery icon and image count on multi-image posts in the feed, so users know a post contains multiple images before tapping.

## What to build
- Parse `is_gallery` boolean and `gallery_data` / `media_metadata` from Reddit API post response
- In `PostCard`, when `post.isGallery == true`, show a small gallery overlay on the thumbnail/image:
  - Stack icon: stacked squares or `Icons.photo_library`
  - Image count badge: "1/N" or "X photos" in a small semi-transparent overlay
- Style: semi-transparent dark pill/capsule in top-right or bottom-right corner of the image/thumbnail area
- The gallery count comes from `gallery_data.items.length` or counting `media_metadata` entries

## Where to inspect
- `lib/src/presentation/widgets/post_card.dart` — image/thumbnail rendering area
- `lib/src/domain/models/post.dart` — check if `isGallery`, `galleryData`, `mediaMetadata` are parsed
- `lib/src/data/api_responses.dart` — JSON mapping for `is_gallery`, `gallery_data`, `media_metadata`

## Implementation notes
- Reddit gallery posts have `is_gallery: true` plus `gallery_data.items` (array of media items with captions) and `media_metadata` (map of media ID → metadata including type, dimensions, URLs)
- The gallery indicator is purely a visual feed overlay — actual gallery viewing is already supported in `media_viewer.dart`
- Use a `Positioned` widget inside a `Stack` for the overlay
- If `gallery_data` is null but post is a gallery (fallback), just show the icon without a count
- Handle non-gallery multi-image posts (rare, but some legacy posts have multiple images without `is_gallery`)
- Coordinate with adaptive image scaling handoff for proper image sizing

## Non-goals
- Showing multiple thumbnails in feed (gallery grid vs single image — keep single image + count badge as official app does in feed)
- Swipeable gallery preview in feed (tap to open full gallery)
- Video/image mixed gallery indicators (just image count, video handled separately)

## Manual test steps
1. `flutter run`
2. Browse feed for multi-image/gallery posts (common in r/pics, r/art, r/gaming)
3. Verify gallery icon + "1/N" count appear on gallery post thumbnails
4. Verify single-image posts have no gallery indicator
5. Tap the gallery post — verify full gallery viewer opens with correct images
6. If using Reddit API test data, verify gallery parsing works for posts with captions
