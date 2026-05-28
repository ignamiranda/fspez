# Handoff: Feed card density modes

## Approved mobile feed quality improvement

Add **feed card density modes** so users can choose between comfortable, compact, and media-focused mobile browsing layouts.

## Current goal

Implement features to reach feature parity with the official Reddit mobile app, prioritizing mobile-app parity and mobile-quality UX.

## Why this improvement

Reddit mobile users browse in different modes:

- Comfortable: balanced title, metadata, actions, and preview.
- Compact: scan many posts quickly with less vertical space.
- Media-focused: emphasize images/video/gallery previews.

A feed density setting makes the app feel more personal and polished without changing core feed behavior.

## Existing related implementation

Inspect these areas first:

- `lib/src/presentation/widgets/post_card.dart`
  - Main card layout, metadata, media preview, action row.
- `lib/src/presentation/widgets/feed_screen_scaffold.dart`
  - Feed list rendering and callbacks.
- `lib/src/presentation/screens/feed_screen.dart`
  - Primary feed screen.
- `lib/src/presentation/screens/subreddit_feed_screen.dart`
  - Subreddit feed screen.
- `lib/src/presentation/screens/search_screen.dart`
  - Search result post cards.
- `lib/src/presentation/screens/user_profile_screen.dart`
  - Profile post lists.
- `lib/main.dart`
  - `SharedPreferences` initialization/override pattern.

Related approved handoffs:

- `handoffs/2026-05-27-in-app-settings-screen-handoff.md`
- `handoffs/2026-05-27-adaptive-image-scaling-handoff.md`
- `handoffs/2026-05-27-gesture-first-media-browsing-handoff.md`
- `handoffs/2026-05-27-bottom-sheet-action-menus-handoff.md`

## Suggested implementation scope

Smallest useful vertical slice:

1. Add a `FeedDensity` setting with values like `comfortable`, `compact`, `mediaFocused`.
2. Persist the setting locally.
3. Apply it to `PostCard` layout everywhere post cards are reused.
4. Add a settings entry or feed-level quick selector if the settings screen exists.
5. Keep default behavior close to the current layout.

## Layout guidance

Comfortable mode:

- Current/default spacing.
- Full title and normal metadata/action emphasis.
- Standard media preview behavior.

Compact mode:

- Reduced vertical padding.
- Smaller metadata/action row.
- Limit preview height or hide previews for low-media posts if needed.
- Preserve vote/save/comment affordances.

Media-focused mode:

- Larger media preview.
- Title/metadata still visible but less dominant.
- Coordinate with adaptive image scaling to avoid ugly cropping.

## UX requirements

- Modes should be easy to understand from labels and maybe a short description.
- Compact mode must remain accessible: avoid tiny tap targets.
- Media-focused mode must not crop ordinary portrait images badly.
- Setting should apply consistently across home, subreddit, search/profile post lists where practical.
- Avoid dead toggles; only expose the setting when at least two visibly different modes work.

## Technical discovery needed

Before editing, inspect:

- Whether `PostCard` is used consistently across all post list surfaces.
- Existing settings/provider patterns, or pending settings screen handoff if not implemented yet.
- Current image preview sizing and how it interacts with adaptive image scaling.
- Whether action row tap targets meet mobile minimums after compacting.

## Deferred out of scope

- Fully separate tablet layouts.
- Per-subreddit density settings.
- User-created custom layouts.
- Rewriting feed architecture.

## Acceptance criteria

- Users can choose at least compact vs comfortable feed card mode.
- Setting persists across app restarts.
- Post cards visually change according to selected density.
- Tap targets remain usable on mobile.
- Existing post actions and media opening behavior do not regress.

## Validation

Run after implementation:

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test` if tests are added/changed.
- Manual `flutter run` checks:
  - Switch density modes and confirm feed cards update.
  - Restart app and confirm selected mode persists.
  - Check feed, subreddit feed, and search/profile post lists if practical.
  - Confirm media previews and actions remain usable.

## Suggested skills / agents

- Use `@designer` for mobile layout/tap-target polish.
- Reuse explorer session `exp-2 Check post edit implementation` for post card/feed context if needed.
- Use `@fixer` for bounded implementation after the setting/provider shape is known.
