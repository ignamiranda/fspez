# TODO: Handoff importance ranking

Maintain this file whenever a new handoff is approved. Add the new handoff into the ranking by importance, not by creation order.

Ranking criteria: mobile Reddit parity, user-visible value, dependency-unblocking value, reliability/safety, implementation leverage, then nice-to-have polish.

## Ranked handoffs

1. `handoffs/2026-05-27-bottom-sheet-action-menus-handoff.md` — approved mobile UX improvement; replace popup menus with thumb-friendly bottom sheets for post actions; high mobile parity value.
2. `handoffs/2026-05-27-optimistic-action-undo-snackbars-handoff.md` — high mobile trust value; makes destructive/reversible actions feel safer and more polished.
3. `handoffs/2026-05-27-nsfw-spoiler-blur-reveal-handoff.md` — core Reddit safety/content expectation and important mobile parity. **Partially done**: PostCard blur/reveal and settings toggles implemented; fullscreen media protection remaining.
4. `handoffs/2026-05-27-mobile-accessibility-comfort-audit-handoff.md` — mobile quality foundation: dynamic text, touch targets, semantics, and reduced motion affect every screen and future UI handoff.
5. `handoffs/2026-05-27-offline-cache-stale-while-revalidate-handoff.md` — major perceived performance/reliability upgrade; makes the app feel instant and resilient.
6. `handoffs/2026-05-27-media-prefetching-feed-handoff.md` — mobile performance polish for media-heavy browsing; valuable after/alongside cache and sensitive-content policy.
7. `handoffs/2026-05-27-pull-to-refresh-polish-handoff.md` — core mobile feed interaction polish; high frequency user action.
8. `handoffs/2026-05-27-mobile-comment-composer-handoff.md` — high-frequency mobile interaction polish: bottom-sheet composer, markdown preview, draft preservation on dismiss, keyboard-safe layout, parent context preview.
9. `handoffs/2026-05-27-gesture-first-media-browsing-handoff.md` — makes existing media viewer feel native-mobile-quality.
10. `handoffs/2026-05-27-media-post-submission-handoff.md` — major official-app parity gap: create image/gallery/video posts, not just text/link.
11. `handoffs/2026-05-27-scroll-to-top-tab-double-tap-handoff.md` — high-frequency mobile UX polish; very cheap to implement; makes navigation feel native.
12. `handoffs/2026-05-27-comment-sort-selector-handoff.md` — core post-detail parity; users expect comment sorting on Reddit.
13. `handoffs/2026-05-27-post-flair-selection-handoff.md` — important for successful submissions in flair-required communities.
14. `handoffs/2026-05-27-user-flair-display-handoff.md` — high-visibility mobile Reddit parity; very cheap (likely API parsing already exists); visible on every post and comment.
15. `handoffs/2026-05-27-report-content-handoff.md` — core safety feature and common Reddit action.
16. `handoffs/2026-05-27-block-unblock-users-handoff.md` — core safety/control feature.
17. `handoffs/2026-05-27-community-mute-unmute-handoff.md` — important feed control and official-app parity.
18. `handoffs/2026-05-27-joined-communities-management-handoff.md` — mobile navigation and account utility; improves discovery of subscribed communities.
19. `handoffs/2026-05-27-swipe-back-gesture-handoff.md` — very high-frequency mobile navigation gesture; affects every pushed screen; simple routing-wide change via `CupertinoPageTransitionsBuilder`.
20. `handoffs/2026-05-27-search-within-subreddit-handoff.md` — high-utility daily feature; reuses existing search infrastructure with `restrict_sr=on`; very cheap.
21. `handoffs/2026-05-27-swipe-gestures-feed-handoff.md` — very high mobile delight; transforms feed interaction; most Reddit-mobile-native gesture pattern.
22. `handoffs/2026-05-27-account-age-karma-profile-handoff.md` — simple visual parity; data already flows from `/user/{username}/about.json`; cheap to implement.
23. `handoffs/2026-05-27-subreddit-time-range-sort-handoff.md` — post-sort polish; cheap UI addition for Top sort (hour/day/week/month/year/all).
24. `handoffs/2026-05-27-multireddit-navigation-handoff.md` — official-app power-user feature; moderate complexity but reuses existing feed infrastructure.
25. `handoffs/2026-05-27-op-indicator-comments-handoff.md` — visible in every comment thread; trivially cheap (one author comparison); strong Reddit-native detail.
26. `handoffs/2026-05-27-sticky-post-indicator-handoff.md` — feed visual parity; cheap (API `stickied` field already parsed); green pin icon for subreddit stickied posts.
27. `handoffs/2026-05-27-autoplay-videos-feed-handoff.md` — high video-browsing UX impact; moderate complexity (scroll visibility detection, single-video management).
28. `handoffs/2026-05-27-image-upload-comments-handoff.md` — enables richer replies with inline images; depends on media-picker from media-post-submission handoff.
29. `handoffs/2026-05-27-custom-home-feed-tabs-handoff.md` — mobile personalization and fast feed switching; valuable after feed/settings foundations exist.
30. `handoffs/2026-05-27-crosspost-indicator-feed-handoff.md` — visible feed parity label on crossposted posts; cheap (API `crosspost_parent` field already in responses).
31. `handoffs/2026-05-27-delete-inbox-messages-handoff.md` — inbox cleanup action; moderate complexity (verify delete endpoint with cookie auth).
32. `handoffs/2026-05-27-gallery-multi-image-indicator-handoff.md` — feed visual; shows gallery icon + image count on multi-image posts; cheap (parse `is_gallery`, `gallery_data`).
33. `handoffs/2026-05-27-feed-density-modes-handoff.md` — mobile personalization and scanning comfort; depends on settings and post-card layout stability. **Settings infrastructure ready** (`FeedDensity` enum and persistence exist).
34. `handoffs/2026-05-27-first-run-account-feed-setup-handoff.md` — onboarding/retention polish; best after settings/feed choices exist.
35. `handoffs/2026-05-27-read-posts-history-sync-handoff.md` — useful feed quality feature; local read-state improves scanning and history continuity.
36. `handoffs/2026-05-27-save-comments-handoff.md` — broad everyday utility; reuses existing save/unsave infrastructure and endpoint; cheap to add to comment overflow menu; comments already appear in saved listing.
37. `handoffs/2026-05-27-live-comment-updates-handoff.md` — post-detail quality improvement; periodic polling with "X new comments" banner; official-app parity for active threads.
38. `handoffs/2026-05-27-recently-visited-communities-users-handoff.md` — useful navigation convenience; lower than joined communities/custom tabs because it is local-only and auxiliary.
39. `handoffs/2026-05-27-local-drafts-handoff.md` — protects user-written content; high quality-of-life for posts/comments/messages.
40. `handoffs/2026-05-27-share-copy-link-actions-handoff.md` — common mobile action with low risk and broad usefulness.
41. `handoffs/2026-05-27-inbox-badge-mark-read-handoff.md` — inbox polish and correctness: unread badge plus actual mark-as-read behavior.
42. `handoffs/2026-05-27-mark-all-inbox-read-handoff.md` — useful inbox bulk action; cheap (one endpoint call or iterated markAsRead).
43. `handoffs/2026-05-27-blocked-users-management-handoff.md` — completes block feature with view/manage/unblock list; depends on block-unblock API confirmation.
44. `handoffs/2026-05-27-muted-communities-management-handoff.md` — completes mute feature with view/manage/unmute list; depends on community-mute API confirmation.
45. `handoffs/2026-05-27-post-save-collections-handoff.md` — post organization feature; official-app parity; moderate complexity (local or server-side collections).
46. `handoffs/2026-05-27-edit-post-remaining-gaps-handoff.md` — completes partial edit behavior; valuable but narrower than missing feature classes.
47. `handoffs/2026-05-27-poll-post-submission-handoff.md` — parity for post creation, but endpoint/auth uncertainty and lower frequency than media/flair.
48. `handoffs/2026-05-27-crosspost-creation-handoff.md` — useful Reddit-native creation flow; lower than core submit/safety/feed features.
49. `handoffs/2026-05-27-subreddit-rules-display-handoff.md` — important for posting safely and community context.
50. `handoffs/2026-05-27-subreddit-sidebar-about-details-handoff.md` — community context polish; useful before deeper community tooling.
51. `handoffs/2026-05-27-subreddit-wiki-pages-handoff.md` — community information parity; lower frequency than rules/about.
52. `handoffs/2026-05-27-moderator-list-display-handoff.md` — useful community transparency; comparatively narrow.
53. `handoffs/2026-05-27-community-notification-levels-handoff.md` — official-app parity, but endpoint/auth uncertainty and push-notification dependencies reduce immediate value.
54. `handoffs/2026-05-27-award-visibility-setting-handoff.md` — lower priority because awards are less central and user explicitly wants visibility disable support. **Settings infrastructure ready** (`showAwards` toggle exists).
55. `handoffs/2026-05-27-moderation-queue-handoff.md` — high value for moderators, but only a subset of users and depends on action/service/list foundations.
56. `handoffs/2026-05-27-moderator-removal-reasons-handoff.md` — important mod workflow, best after modqueue/remove flows exist.
57. `handoffs/2026-05-27-moderator-ban-unban-users-handoff.md` — powerful mod action; needs careful auth/safety and moderator context.
58. `handoffs/2026-05-27-moderator-user-notes-handoff.md` — advanced moderator workflow; useful after basic mod surfaces exist.
59. `handoffs/2026-05-27-modmail-access-handoff.md` — advanced moderator feature with significant endpoint/auth uncertainty; start read-only when reached.

## Completed

- **Centralize Reddit thing actions** — Added `PostActionsService` and provider wiring to route post vote/save/hide/unhide/delete/edit through one use-case service while preserving existing notifier semantics. Feed/detail/edit UI now call the service instead of directly coordinating action notifiers. Added service tests for routing and optimistic save/vote/hide/delete/edit behavior. All 200 tests pass.
- **Standardize paginated list state** — Created `PaginatedResult<T>` and `PaginatedNotifier<T>` concrete base class. Eliminated `FeedPageState` (replaced with `PaginatedListState<Post>`) and `SearchResultPage<T>` (replaced with `PaginatedResult<T>`). `FeedPageNotifier` and search providers now extend `PaginatedNotifier<T>`, removing ~80 lines of boilerplate. `InboxNotifier` remains on `CursorPaginatedNotifier` (has extra state). All 194 tests pass.
- **In-app settings screen** — Settings UI with theme picker, blur toggles, feed density, comment sort. `AppThemeMode`/`FeedDensity` enums, `AppSettingsNotifier` persistence, `PostCard` blur/reveal, AMOLED theme. (No handoff file existed; was TODO item #1)
- **Dark mode/theme support** — Light/Dark/AMOLED/System theme switching with persistence via `AppThemeMode`. `FspezTheme.amoled()` with pure black backgrounds. (Was handoff #23)
- **Subreddit icon display in feed cards** — Added 20×20 circular subreddit icon (from `sr_detail.icon_img`) next to `r/name` in `PostCard._MetadataRow`; graceful empty on missing/error. (Was handoff #17)
- **Relative timestamps across all surfaces** — Comment timestamps now display `timeAgo()` in `CommentTree` header (author · relative time); `timeAgo` already covered feed, post detail, and inbox. (Was handoff #28)

## Notes

- If duplicate/superseded handoffs exist, prefer the broader/more current handoff and delete or archive obsolete ones when implementation starts.
- User-facing UI/Reddit behavior changes should include manual test steps in final reports.
- Prioritize mobile-app parity and mobile-quality UX over desktop-only enhancements.
