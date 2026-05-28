# Handoff: Mobile accessibility and comfort audit

## Approved mobile accessibility/comfort improvement

Audit and improve **dynamic text, touch targets, and reduced motion** across core mobile UI.

## Current goal

Implement features to reach feature parity with the official Reddit mobile app, prioritizing mobile-app parity, mobile-quality UX, architecture, reliability, accessibility, performance, and overall app quality.

## Why this improvement

Best-in-class mobile apps respect system accessibility preferences. Reddit browsing involves dense post cards, nested comments, forms, media controls, and action sheets; these must remain usable with larger fonts, touch accessibility needs, and reduced-motion settings.

## Existing related implementation

Inspect these areas first:

- `lib/src/presentation/widgets/post_card.dart`
  - Dense feed card layout, metadata, media, and actions.
- `lib/src/presentation/widgets/comment_tree.dart`
  - Nested comments, collapse/expand, reply/edit/delete actions.
- `lib/src/presentation/widgets/media_viewer.dart`
  - Fullscreen media controls, gestures, animations.
- `lib/src/presentation/widgets/feed_screen_scaffold.dart`
  - Feed list structure and scroll behavior.
- `lib/src/presentation/screens/post_detail_screen.dart`
  - Post header, comments, reply/edit flows.
- `lib/src/presentation/screens/submit_screen.dart`
  - Post submission form.
- `lib/src/presentation/screens/compose_screen.dart`
  - Direct message compose form.
- Any bottom sheets/dialogs introduced by approved action-menu handoffs.

Related approved handoffs:

- `handoffs/2026-05-27-bottom-sheet-action-menus-handoff.md`
- `handoffs/2026-05-27-feed-density-modes-handoff.md`
- `handoffs/2026-05-27-gesture-first-media-browsing-handoff.md`
- `handoffs/2026-05-27-first-run-account-feed-setup-handoff.md`

## Suggested implementation scope

Smallest useful vertical slice:

1. Audit core screens at increased text scale.
2. Fix obvious overflow/clipping in post cards, comments, forms, and action controls.
3. Ensure primary touch targets are at least mobile-friendly size.
4. Add semantic labels/tooltips where icon-only actions are unclear.
5. Respect reduced-motion/accessibility settings for non-essential animations where practical.
6. Add focused widget tests for the worst overflow/accessibility regressions.

## UX/accessibility requirements

- Text should scale without critical clipping or unreadable overlap.
- Icon-only actions must have accessible labels.
- Vote/save/reply/share/menu controls should remain tappable at larger text sizes.
- Nested comments should remain readable and not collapse into unusable narrow columns.
- Reduced motion should disable or simplify non-essential animations without breaking navigation.
- Compact feed mode must not produce inaccessible tap targets.

## Technical discovery needed

Before editing, inspect:

- Current Material theme/text style usage.
- Whether widgets use fixed heights that break with text scaling.
- Current `AnimatedSize`, media viewer transitions, and any custom animations.
- Flutter APIs available for text scaler / accessibility features in the project’s SDK version.
- Existing widget test patterns for post cards/comment trees.

## Architecture guidance

- Prefer theme/text-style fixes over per-widget magic constants.
- Avoid globally disabling text scaling.
- Keep accessibility helpers small and reusable if repeated patterns emerge.
- Coordinate with feed density and bottom-sheet work so new UI does not regress accessibility.

## Deferred out of scope

- Full screen-reader certification pass.
- Platform-native accessibility settings UI.
- Complete redesign of comment threading.
- Desktop keyboard shortcut work unless it directly benefits mobile accessibility.

## Acceptance criteria

- Core feed, post detail, comments, media viewer, submit, and compose screens handle larger text better than before.
- Primary touch targets are mobile-friendly.
- Key icon-only actions expose semantic labels.
- Reduced-motion preferences are respected for at least the most obvious non-essential animations.
- No critical layout regressions at normal text scale.

## Validation

Run after implementation:

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test` if tests are added/changed.
- Manual `flutter run` checks:
  - Increase system/app text scale if possible and inspect feed, post detail, comments, submit, compose, and media viewer.
  - Verify action buttons remain tappable.
  - Verify no major overflow/clipping in post cards or comments.
  - Enable reduced motion if available and confirm animations remain comfortable.

## Suggested skills / agents

- Use `@designer` for accessibility-focused mobile layout review and fixes.
- Reuse explorer session `exp-2 Check post edit implementation` for post card/comment/form context if needed.
- Use `@fixer` for bounded fixes after the audit identifies concrete widgets.
- Use `@oracle` only if accessibility changes require broad theme/layout architecture decisions.
