# TODO: Handoff importance ranking

Maintain this file whenever a new handoff is approved. Add the new handoff into the ranking by importance, not by creation order.

Ranking criteria: mobile Reddit parity, user-visible value, dependency-unblocking value, reliability/safety, implementation leverage, then nice-to-have polish.

## Ranked handoffs

- ~~`handoffs/2026-05-27-mobile-comment-composer-handoff.md`~~ — done: bottom-sheet composer, markdown toolbar, preview toggle, parent-context preview, draft preservation, keyboard-safe layout, inline error handling.
- `handoffs/2026-05-27-gesture-first-media-browsing-handoff.md` — makes existing media viewer feel native-mobile-quality.
- `handoffs/2026-05-27-media-post-submission-handoff.md` — major official-app parity gap: create image/gallery/video posts, not just text/link.
- `handoffs/2026-05-27-scroll-to-top-tab-double-tap-handoff.md` — high-frequency mobile UX polish; very cheap to implement; makes navigation feel native.
- `handoffs/2026-05-27-post-flair-selection-handoff.md` — important for successful submissions in flair-required communities.
- `handoffs/2026-05-27-user-flair-display-handoff.md` — high-visibility mobile Reddit parity; very cheap (likely API parsing already exists); visible on every post and comment.
- `handoffs/2026-05-27-report-content-handoff.md` — core safety feature and common Reddit action.
- `handoffs/2026-05-27-block-unblock-users-handoff.md` — core safety/control feature.
- `handoffs/2026-05-27-community-mute-unmute-handoff.md` — important feed control and official-app parity.
- `handoffs/2026-05-27-joined-communities-management-handoff.md` — mobile navigation and account utility; improves discovery of subscribed communities.
- `handoffs/2026-05-27-swipe-back-gesture-handoff.md` — very high-frequency mobile navigation gesture; affects every pushed screen; simple routing-wide change via `CupertinoPageTransitionsBuilder`.
- `handoffs/2026-05-27-swipe-gestures-feed-handoff.md` — very high mobile delight; transforms feed interaction; most Reddit-mobile-native gesture pattern.
- `handoffs/2026-05-27-account-age-karma-profile-handoff.md` — simple visual parity; data already flows from `/user/{username}/about.json`; cheap to implement.
- `handoffs/2026-05-27-subreddit-time-range-sort-handoff.md` — post-sort polish; cheap UI addition for Top sort (hour/day/week/month/year/all).
- `handoffs/2026-05-27-multireddit-navigation-handoff.md` — official-app power-user feature; moderate complexity but reuses existing feed infrastructure.
- `handoffs/2026-05-27-op-indicator-comments-handoff.md` — visible in every comment thread; trivially cheap (one author comparison); strong Reddit-native detail.
- `handoffs/2026-05-27-sticky-post-indicator-handoff.md` — feed visual parity; cheap (API `stickied` field already parsed); green pin icon for subreddit stickied posts.
- `handoffs/2026-05-27-autoplay-videos-feed-handoff.md` — high video-browsing UX impact; moderate complexity (scroll visibility detection, single-video management).
- `handoffs/2026-05-27-image-upload-comments-handoff.md` — enables richer replies with inline images; depends on media-picker from media-post-submission handoff.
- `handoffs/2026-05-27-custom-home-feed-tabs-handoff.md` — mobile personalization and fast feed switching; valuable after feed/settings foundations exist.
- `handoffs/2026-05-27-crosspost-indicator-feed-handoff.md` — visible feed parity label on crossposted posts; cheap (API `crosspost_parent` field already in responses).
- `handoffs/2026-05-27-delete-inbox-messages-handoff.md` — inbox cleanup action; moderate complexity (verify delete endpoint with cookie auth).
- `handoffs/2026-05-27-gallery-multi-image-indicator-handoff.md` — feed visual; shows gallery icon + image count on multi-image posts; cheap (parse `is_gallery`, `gallery_data`).
- `handoffs/2026-05-27-feed-density-modes-handoff.md` — mobile personalization and scanning comfort; depends on settings and post-card layout stability. **Settings infrastructure ready** (`FeedDensity` enum and persistence exist).
- `handoffs/2026-05-27-first-run-account-feed-setup-handoff.md` — onboarding/retention polish; best after settings/feed choices exist.
- `handoffs/2026-05-27-read-posts-history-sync-handoff.md` — useful feed quality feature; local read-state improves scanning and history continuity.
- `handoffs/2026-05-27-save-comments-handoff.md` — broad everyday utility; reuses existing save/unsave infrastructure and endpoint; cheap to add to comment overflow menu; comments already appear in saved listing.
- `handoffs/2026-05-27-live-comment-updates-handoff.md` — post-detail quality improvement; periodic polling with "X new comments" banner; official-app parity for active threads.
- `handoffs/2026-05-27-recently-visited-communities-users-handoff.md` — useful navigation convenience; lower than joined communities/custom tabs because it is local-only and auxiliary.
- `handoffs/2026-05-27-local-drafts-handoff.md` — protects user-written content; high quality-of-life for posts/comments/messages.
- `handoffs/2026-05-27-share-copy-link-actions-handoff.md` — common mobile action with low risk and broad usefulness.
- `handoffs/2026-05-27-mark-all-inbox-read-handoff.md` — useful inbox bulk action; cheap (one endpoint call or iterated markAsRead).
- `handoffs/2026-05-27-blocked-users-management-handoff.md` — completes block feature with view/manage/unblock list; depends on block-unblock API confirmation.
- `handoffs/2026-05-27-muted-communities-management-handoff.md` — completes mute feature with view/manage/unmute list; depends on community-mute API confirmation.
- `handoffs/2026-05-27-post-save-collections-handoff.md` — post organization feature; official-app parity; moderate complexity (local or server-side collections).
- `handoffs/2026-05-27-edit-post-remaining-gaps-handoff.md` — completes partial edit behavior; valuable but narrower than missing feature classes.
- `handoffs/2026-05-27-poll-post-submission-handoff.md` — parity for post creation, but endpoint/auth uncertainty and lower frequency than media/flair.
- `handoffs/2026-05-27-crosspost-creation-handoff.md` — useful Reddit-native creation flow; lower than core submit/safety/feed features.
- `handoffs/2026-05-27-subreddit-rules-display-handoff.md` — important for posting safely and community context.
- `handoffs/2026-05-27-subreddit-wiki-pages-handoff.md` — community information parity; lower frequency than rules/about.
- `handoffs/2026-05-27-moderator-list-display-handoff.md` — useful community transparency; comparatively narrow.
- `handoffs/2026-05-27-community-notification-levels-handoff.md` — official-app parity, but endpoint/auth uncertainty and push-notification dependencies reduce immediate value.
- `handoffs/2026-05-27-moderation-queue-handoff.md` — high value for moderators, but only a subset of users and depends on action/service/list foundations.
- `handoffs/2026-05-27-moderator-removal-reasons-handoff.md` — important mod workflow, best after modqueue/remove flows exist.
- `handoffs/2026-05-27-moderator-ban-unban-users-handoff.md` — powerful mod action; needs careful auth/safety and moderator context.
- `handoffs/2026-05-27-moderator-user-notes-handoff.md` — advanced moderator workflow; useful after basic mod surfaces exist.
- `handoffs/2026-05-27-modmail-access-handoff.md` — advanced moderator feature with significant endpoint/auth uncertainty; start read-only when reached.

## Completed

- **Mobile comment composer** — Created `CommentComposerSheet` reusable bottom-sheet with markdown toolbar (B/I/S/~link/quote/code/bullet), preview toggle, parent-context preview, send flow with loading/inline error, keyboard-safe layout, draft preservation on dismiss. Integrated into `PostDetailScreen` replacing inline input bar. Handoff file deleted.
- **Pull-to-refresh polish** — Added haptic feedback on pull (`HapticFeedback.mediumImpact()`), refresh result snackbars ("N new posts loaded", "You're up to date", "Could not refresh"), and scroll-position preservation (anchor to first item after new content loads). Applied to both main feed and subreddit feed via `FeedScreenScaffold.onRefresh`. Handoff file deleted.
- **Inbox unread badge** — Already implemented in current codebase: `/message/unread.json` fetch path, unread count provider wiring, `_MainShell` badge UI, and notifier refresh behavior for initial load/mark-as-read flows. Handoff removed as complete.
- **Centralize Reddit thing actions** — Added `PostActionsService` and provider wiring to route post vote/save/hide/unhide/delete/edit through one use-case service while preserving existing notifier semantics. Feed/detail/edit UI now call the service instead of directly coordinating action notifiers. Added service tests for routing and optimistic save/vote/hide/delete/edit behavior. All 200 tests pass.
- **Standardize paginated list state** — Created `PaginatedResult<T>` and `PaginatedNotifier<T>` concrete base class. Eliminated `FeedPageState` (replaced with `PaginatedListState<Post>`) and `SearchResultPage<T>` (replaced with `PaginatedResult<T>`). `FeedPageNotifier` and search providers now extend `PaginatedNotifier<T>`, removing ~80 lines of boilerplate. `InboxNotifier` remains on `CursorPaginatedNotifier` (has extra state). All 194 tests pass.
- **In-app settings screen** — Settings UI with theme picker, blur toggles, feed density, comment sort. `AppThemeMode`/`FeedDensity` enums, `AppSettingsNotifier` persistence, `PostCard` blur/reveal, AMOLED theme. (No handoff file existed; was TODO item #1)
- **Dark mode/theme support** — Light/Dark/AMOLED/System theme switching with persistence via `AppThemeMode`. `FspezTheme.amoled()` with pure black backgrounds. (Was handoff #23)
- **Subreddit icon display in feed cards** — Added 20×20 circular subreddit icon (from `sr_detail.icon_img`) next to `r/name` in `PostCard._MetadataRow`; graceful empty on missing/error. (Was handoff #17)
- **Relative timestamps across all surfaces** — Comment timestamps now display `timeAgo()` in `CommentTree` header (author · relative time); `timeAgo` already covered feed, post detail, and inbox. (Was handoff #28)
- **Mobile accessibility comfort audit** — Applied foundational comfort improvements: larger nav labels/height for dynamic text readability, 48×48 minimum tap targets via shared button theme, expanded list-tile vertical padding, reduced-motion behavior for feed scroll-to-top (jump instead of animate when accessibility reduce-motion is enabled), feed action tooltips, and explicit inbox badge semantics label for screen readers. Source handoff file was already absent from `handoffs/`; completed from ranked TODO scope.
- **Optimistic action undo snackbars** — Completed remaining gaps from prior partial state for destructive/reversible actions: feed delete now uses an undo grace window (optimistically removes item, allows Undo for 4s, then finalizes delete). Existing save/hide/unhide undo behavior preserved. Vote actions intentionally remain snackbar-free to avoid interaction clutter. Source handoff file was already absent from `handoffs/`; completed from ranked TODO scope.
- **Offline cache + stale-while-revalidate feeds** — Implemented first-page feed cache with per-account/per-config keys, stale metadata (TTL), cache-seeded initial rendering, background refresh, stale/error status banners, and preserved-content-on-refresh-failure behavior. Added explicit feed cache invalidation on account removal/logout to prevent account-data bleed.
- **Comment sort selector** — Added sort selector to `PostDetailScreen` with Best/Top/New/Controversial/Old, bottom-sheet picker, reload on change, and default sort persistence in settings. Handoff file deleted.
- **Subreddit sidebar/about details** — Added `_SubredditAboutSheet` with description, member count, online count, created date, NSFW/quarantine/restricted/private status, and sidebar markdown rendering. Handoff file deleted.
- **Award visibility setting** — Added `showAwards` toggle in settings, award count parsing for posts/comments, and `AwardBadge` display on feed cards, post detail, and comments. Handoff file deleted.
- **Inbox badge and mark-as-read** — Added unread count provider and badge on inbox nav item, and wired `markAsRead` in inbox notifier to repository call with local unread count decrement. Handoff file deleted.
- **Feed image/media prefetching** — Created `FeedMediaPrefetcher` widget that precaches image URLs for upcoming feed cards using Flutter's built-in image cache. Prefetches N=5 posts ahead based on estimated scroll position. Respects NSFW/spoiler blur settings. Added `prefetchMedia` toggle (default on) to settings. Wired into both feed and subreddit feed via `FeedScreenScaffold`. Handoff file deleted.

## Notes

- If duplicate/superseded handoffs exist, prefer the broader/more current handoff and delete or archive obsolete ones when implementation starts.
- User-facing UI/Reddit behavior changes should include manual test steps in final reports.
- Prioritize mobile-app parity and mobile-quality UX over desktop-only enhancements.
