# Handoff: Offline cache and stale-while-revalidate feeds

## Approved quality/performance improvement

Implement **offline cache + stale-while-revalidate** behavior for high-traffic Reddit surfaces.

## Current goal

Implement features to reach feature parity with the official Reddit mobile app, while also improving architecture, UX polish, reliability, performance, and overall app quality.

## Why this improvement

Official-grade apps feel instant and resilient. Today, feed-like surfaces likely depend heavily on live network requests. Caching recent data locally and revalidating in the background would:

- Make app launch and tab switches feel faster.
- Preserve useful content during flaky network conditions.
- Reduce repeated fetches when navigating back and forth.
- Provide a stronger foundation for future features like read-state, drafts, joined communities, modqueue, and offline-friendly browsing.

## Existing related implementation

Inspect these areas first:

- `lib/src/data/feed_pagination.dart`
  - Existing feed pagination/cursor state.
- `lib/src/data/reddit_client.dart`
  - Low-level fetch methods and endpoint normalization.
- `lib/src/presentation/screens/feed_screen.dart`
  - Home/popular feed loading and sorting.
- `lib/src/presentation/screens/subreddit_feed_screen.dart`
  - Subreddit feed loading.
- `lib/src/presentation/screens/post_detail_screen.dart`
  - Post detail/comment loading and navigation return behavior.
- `lib/src/presentation/screens/search_screen.dart`
  - Search results; consider later because search cache semantics may differ.
- `lib/main.dart`
  - Current `SharedPreferences` initialization. Determine whether this is enough or whether a richer local store is needed.
- `pubspec.yaml`
  - Existing persistence dependencies.

Related approved handoffs:

- `handoffs/2026-05-27-standardize-paginated-list-state-handoff.md`
- `handoffs/2026-05-27-read-posts-history-sync-handoff.md`
- `handoffs/2026-05-27-joined-communities-management-handoff.md`
- `handoffs/2026-05-27-centralize-thing-actions-handoff.md`

## Suggested implementation scope

Smallest useful vertical slice:

1. Cache the first page of the primary feed for each feed key.
   - Feed key examples: home/popular/all + sort, subreddit + sort.
2. On screen load, immediately show cached posts if present.
3. Trigger a background refresh and replace/merge with fresh network data.
4. Show stale-state UI subtly if cached content is older than a threshold.
5. If network refresh fails, keep cached content visible and show a non-blocking error/retry affordance.
6. Add cache invalidation for account switching and logout where needed.

## Technical discovery needed

Before editing, inspect:

- Whether `Post` models can be serialized/deserialized manually today.
- Whether current API response models are easier to cache than domain models.
- Existing account/session identity available for cache keys.
- Whether `SharedPreferences` is acceptable for small first-page JSON blobs.
  - If not, consider a small local database/file cache, but avoid broad dependency churn unless justified.
- How optimistic actions should update cached copies.
  - Initial slice can defer cache mutation after writes if UI state remains correct, but document the limitation.
- Whether NSFW/private/account-specific content means caches must be per account.

## UX requirements

- Cached content should appear quickly and not block on the network.
- Refresh indicators should distinguish active loading from background revalidation.
- If content is stale, communicate subtly without making the app feel broken.
- Network failures should not blank a populated cached feed.
- Account-specific cached data must not bleed across accounts.

## Architecture requirements

- Keep cache policy outside UI widgets where possible.
- Do not make `RedditClient` responsible for persistent storage; prefer repository/cache wrappers.
- Use explicit cache keys and TTL/staleness metadata.
- Keep the first implementation narrow enough to verify before applying to every list.

## Deferred out of scope

- Full offline write queue.
- Caching every search result or infinite-scroll page.
- Conflict resolution for writes while offline.
- Media file caching.
- Global cache management UI, unless trivial.

## Acceptance criteria

- At least one primary feed surface loads cached content immediately when available.
- Background refresh updates the visible list without requiring manual reload.
- Refresh failure preserves cached content.
- Cache is isolated per account/session where necessary.
- Stale metadata is stored and used for UI or refresh decisions.
- Existing feed pagination behavior remains intact.

## Validation

Run after implementation:

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test` if tests are added/changed.
- Manual `flutter run` checks:
  - Load a feed, quit/restart, confirm cached content appears quickly.
  - Confirm background refresh updates content.
  - Simulate network failure if practical and confirm cached content remains visible.
  - Switch accounts if practical and confirm feed cache does not bleed across users.

## Suggested skills / agents

- Use `@oracle` before choosing a persistence backend if `SharedPreferences` looks insufficient.
- Reuse explorer session `exp-2 Check post edit implementation` for feed/subreddit/client context if more discovery is needed.
- Use `@fixer` for bounded implementation after cache key shape and first surface are chosen.
- Use `@designer` if stale/offline UI states need polish.
