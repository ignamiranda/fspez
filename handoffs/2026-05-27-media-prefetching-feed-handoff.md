# Handoff: Feed image/media prefetching

## Approved mobile performance improvement

Implement **image/media prefetching for the next few feed cards** so browsing and opening media feels faster on mobile.

## Current goal

Implement features to reach feature parity with the official Reddit mobile app, prioritizing mobile-app parity, mobile-quality UX, architecture, reliability, performance, and overall app quality.

## Why this improvement

Mobile Reddit browsing is media-heavy. Users expect image posts and galleries to appear quickly as they scroll and open media. Limited, policy-aware prefetching can improve perceived speed without wasting data, battery, or memory.

## Existing related implementation

Inspect these areas first:

- `lib/src/presentation/widgets/post_card.dart`
  - Inline media preview loading and media tap/open behavior.
- `lib/src/presentation/widgets/media_viewer.dart`
  - Fullscreen image/gallery/video loading.
- `lib/src/presentation/widgets/feed_screen_scaffold.dart`
  - Feed list rendering, scroll position, visible post context.
- `lib/src/presentation/screens/feed_screen.dart`
  - Primary feed source and refresh behavior.
- `lib/src/presentation/screens/subreddit_feed_screen.dart`
  - Subreddit feed source and refresh behavior.
- `lib/src/domain/models/post.dart`
  - Media URL/thumbnail/gallery/spoiler/NSFW fields.
- `pubspec.yaml`
  - Existing image/cache dependencies.

Related approved handoffs:

- `handoffs/2026-05-27-offline-cache-stale-while-revalidate-handoff.md`
- `handoffs/2026-05-27-nsfw-spoiler-blur-reveal-handoff.md`
- `handoffs/2026-05-27-adaptive-image-scaling-handoff.md`
- `handoffs/2026-05-27-gesture-first-media-browsing-handoff.md`

## Suggested implementation scope

Smallest useful vertical slice:

1. Identify preview image URLs for posts currently near the viewport.
2. Prefetch images for the next small window of posts, e.g. 3–5 cards ahead.
3. Use Flutter image cache or existing cache package rather than inventing a large media cache.
4. Skip or limit prefetching for:
   - NSFW media unless revealed or settings allow it.
   - Spoiler media unless revealed or settings allow it.
   - Very large media/video files.
   - Metered/low-data mode if such a setting exists later.
5. Add guardrails for memory/network pressure.
6. Apply first to feed and subreddit feed; expand later if stable.

## UX/performance requirements

- Prefetch should make scrolling/opening media faster without visible UI noise.
- It must not cause jank while scrolling.
- It must not aggressively download videos or full-size galleries by default.
- Respect sensitive-content blur/reveal policy.
- If prefetch fails, user-visible loading should still work normally.

## Technical discovery needed

Before editing, inspect:

- Whether images use `Image.network`, `CachedNetworkImage`, or another loader.
- Whether post media URLs are direct image URLs, thumbnails, preview images, or gallery item URLs.
- Current image cache configuration and memory behavior.
- Whether list widgets expose enough scroll/visibility information.
- Whether a lightweight prefetch service/provider can operate from feed item indexes without coupling to UI internals.

## Architecture guidance

- Keep prefetch policy in a small service/helper, not scattered through `PostCard`.
- UI should notify the prefetcher about current/nearby posts; prefetcher decides what URLs are safe and worth preloading.
- Coordinate with offline cache work: this is media preview cache/prefetch, not feed JSON persistence.
- Keep implementation narrow and measurable; avoid broad cache-system redesign.

## Deferred out of scope

- Full offline media downloads.
- Video preloading/autoplay pipeline.
- Background prefetch when app is not open.
- User-facing cache size management.
- Predictive recommendation prefetching beyond currently loaded feed items.

## Acceptance criteria

- Feed and subreddit feed prefetch preview images for a bounded number of upcoming posts.
- Sensitive NSFW/spoiler content is not prefetched unless policy allows it.
- Prefetch failures do not break normal media loading.
- Scrolling remains smooth.
- Implementation has clear limits for number/size/type of prefetched media.

## Validation

Run after implementation:

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test` if tests are added/changed.
- Manual `flutter run` checks:
  - Scroll an image-heavy feed and confirm upcoming images appear faster.
  - Open prefetched image posts fullscreen and confirm quick display.
  - Confirm NSFW/spoiler media is not prefetched/revealed unexpectedly.
  - Confirm no obvious scroll jank or runaway network usage.

## Suggested agents

- Use `@oracle` if choosing between Flutter image cache, dependency cache, or custom cache policy becomes ambiguous.
- Reuse explorer session `exp-2 Check post edit implementation` for feed/post/media context if needed.
- Use `@fixer` for bounded implementation after image loading path and prefetch policy are clear.
- Use `@designer` only if loading/reveal UX needs visible polish.
