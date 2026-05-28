# Scroll-to-top on bottom-nav tab double-tap

## Problem

The official Reddit mobile app scrolls the feed to the top when you tap the currently active bottom-nav tab. fspez lacks this behavior — users must manually flick-scroll back to the top of a long feed, which is tedious and feels unpolished.

## Scope

**Tab double-tap → scroll to top:**
- When the user taps an already-active bottom nav tab (Feed, Inbox, Account), scroll the visible content list to the top
- Smooth animated scroll (not instant jump)
- Only applies to the currently active tab — tapping a different tab switches as normal

**Screens to target:**
- **Feed** (home/popular/subscribed feed) — both aggregated and per-subreddit feeds
- **Inbox** — scroll message list to top
- **Account** — if there's a scrollable list (saved/hidden/history entries), scroll those to top too

**Implementation approach:**
- Each screen's scroll state is managed by a `ScrollController` exposed via a provider, a callback on `_MainShell`, or a simpler pattern
- `_MainShell` in `lib/src/presentation/app.dart` receives the tab tap and checks if it's a repeat tap on the currently active tab
- If yes, call `scrollController.animateTo(0, ...)` on the current screen's controller
- Use a `ValueNotifier<ScrollController>` or `GlobalKey` scheme to wire the current screen's controller to the shell

**Edge cases:**
- Screen is already at the top — no-op, no animation
- Screen is still loading or empty — no-op
- Multiple scrollable regions (e.g., tabs within Inbox) — scroll the primary list; if sub-tabs are toggled, consider which one is active
- Subreddit feed within a subreddit screen — same treatment as main feed

## Out of scope

- Double-tap on app bar / top area (if present)
- Scroll-to-top for non-tab content (e.g., post detail, fullscreen media)
- Haptic feedback on double-tap (optional later polish)
- Scroll-to-top on notification arrival

## Implementation notes

- The tab switching logic is in `lib/src/presentation/app.dart` (`_MainShell` with `IndexedStack`)
- Each screen (FeedScreen, InboxScreen, AccountScreen) likely owns its own `ScrollController`
- Simplest approach: use a `ValueNotifier<int?>` for last tapped tab index + timestamp or a callback that wires into each screen's `ScrollController`
- No new dependencies
- Test on all three tabs: tap feed → scroll down → tap Feed tab again → scrolls to top
