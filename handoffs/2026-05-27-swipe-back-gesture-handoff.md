# Swipe back gesture navigation

## Scope
Add swipe left-to-right to go back from detail screens (post detail, subreddit feed, user profile, search results, inbox, submit/compose), matching official Reddit mobile navigation.

## What to build
- Enable iOS-style swipe-back gesture for all `Navigator` push transitions in the app
- Flutter's `MaterialPageRoute` supports `CupertinoPageRoute`-style back gesture by default on mobile — ensure it's enabled on all routes
- For Windows desktop: keep the gesture available but also respect that mouse users may not use it (it won't interfere)
- Ensure gesture doesn't conflict with:
  - Horizontal `PageView` or `TabBarView` (inbox tabs, post detail tabs)
  - `Dismissible` widgets (feed swipe gestures handoff)
  - Sliding drawers or end drawers
  - Image gallery horizontal swipe

## Where to inspect
- `lib/src/presentation/app.dart` — route generation and navigation setup
- All screens pushed via `Navigator.push` or `Navigator.pushNamed` — check transition type
- Search for `MaterialPageRoute`, `CupertinoPageRoute`, or custom `Route` classes
- Screens with horizontal scrolling that could conflict: `post_detail_screen.dart`, `inbox_screen.dart`, `submit_screen.dart`, `media_viewer.dart`

## Implementation notes
- Flutter's default `MaterialPageRoute` on desktop Windows does NOT include the iOS back-swipe gesture; need to ensure it uses `CupertinoPageRoute` or custom `buildTransitions`
- Easiest approach: use `CupertinoPageRoute` for all routes, or set `ThemeData.pageTransitionsTheme` to use `CupertinoPageTransitionsBuilder` for all platforms
- Gesture conflict resolution: wrap conflicting horizontal gestures with `GestureDetector(behavior: HitTestBehavior.opaque)` only when needed, or use `PageRoute` that ignores the back gesture when `NestedScrollView` is scrolling horizontally
- For the `media_viewer.dart` gallery: the page view needs to take priority over back gesture; use `PageView` with `physics: PageScrollPhysics()` which should handle this

## Non-goals
- Custom back-gesture animation speed or threshold
- Parallax or hero transitions (keep it simple)
- Edge-swipe to go forward (Android-style)

## Manual test steps
1. `flutter run`
2. Tap a post from feed → post detail
3. Swipe left-to-right from left edge → navigate back to feed
4. Tap a subreddit → subreddit feed → swipe back
5. Tap a username → user profile → swipe back
6. Go to inbox → tap a message → swipe back
7. Go to search → tap a result → swipe back
8. Open a multi-image post → swipe through gallery images → verify gallery swipe still works (no back navigation conflict)
