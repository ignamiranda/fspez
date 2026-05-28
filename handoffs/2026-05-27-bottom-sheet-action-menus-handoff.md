# Handoff: Mobile bottom-sheet action menus

## Approved mobile UX improvement

Replace or augment dense post/comment overflow menus with **thumb-friendly mobile bottom-sheet action menus**.

## Current goal

Implement features to reach feature parity with the official Reddit mobile app, prioritizing mobile-app parity and mobile-quality UX.

## Why this improvement

Mobile Reddit actions should be easy to scan and hit with a thumb. As feature parity grows, post/comment menus will include save, hide, edit, delete, report, block, share/copy, crosspost, moderation actions, and more. A grouped bottom sheet scales better than dense popup menus and gives destructive actions room for confirmations and clearer labels.

## Existing related implementation

Inspect these areas first:

- `lib/src/presentation/widgets/post_card.dart`
  - Current post overflow actions such as save/hide/delete/edit.
- `lib/src/presentation/widgets/comment_tree.dart`
  - Current comment actions such as reply/edit/delete.
- `lib/src/presentation/screens/post_detail_screen.dart`
  - Post detail/comment action wiring.
- `lib/src/presentation/widgets/feed_screen_scaffold.dart`
  - Feed-level action callbacks passed into post cards.

Related approved handoffs that will add menu actions:

- `handoffs/2026-05-27-share-copy-link-actions-handoff.md`
- `handoffs/2026-05-27-report-content-handoff.md`
- `handoffs/2026-05-27-block-unblock-users-handoff.md`
- `handoffs/2026-05-27-crosspost-creation-handoff.md`
- `handoffs/2026-05-27-moderation-queue-handoff.md`
- `handoffs/2026-05-27-moderator-removal-reasons-handoff.md`

## Suggested implementation scope

Smallest useful vertical slice:

1. Create a reusable post action bottom sheet.
2. Migrate `PostCard` overflow actions to open the bottom sheet on mobile-first layouts.
3. Group actions clearly:
   - Primary actions: save, hide, share/copy, crosspost when available.
   - Author actions: edit, delete.
   - Safety actions: report, block user.
   - Moderator actions: approve/remove/ban when available later.
4. Use confirmation dialogs/sheets for destructive actions like delete and remove.
5. Create or plan a matching comment action bottom sheet after post sheet behavior is proven.

## UX requirements

- Actions should be large enough for touch.
- Use icons plus labels where it improves scanability.
- Hide unavailable actions instead of showing dead disabled rows.
- Destructive actions should be visually distinct and require confirmation.
- Keep sheet height reasonable; use grouped sections if many actions are present.
- Sheet should dismiss cleanly after successful action or stay open only when useful.

## Technical discovery needed

Before editing, inspect:

- Whether existing menus use `PopupMenuButton`, `showModalBottomSheet`, or custom widgets.
- Current callback signatures for post/comment actions.
- Whether action availability is determined in UI or data/notifier layer.
- Existing confirmation dialog patterns.
- Existing theme spacing, icons, and Material version conventions.

## Architecture guidance

- Keep bottom sheets presentational; do not put Reddit endpoint logic inside them.
- Prefer passing an action model/list into the sheet if it avoids duplicating post/comment menu layout.
- Coordinate with `centralize-thing-actions-handoff` if implementing action services first.
- Avoid creating a complex generic menu framework until both post and comment sheets need shared behavior.

## Deferred out of scope

- Full redesign of all navigation.
- Moderator-specific actions unless their underlying endpoints are already implemented.
- Native platform share sheet; covered by share/copy handoff.
- Tablet-specific adaptive layouts, unless trivial.

## Acceptance criteria

- Post overflow opens a mobile-friendly bottom sheet with existing actions.
- Existing save/hide/edit/delete behavior remains unchanged.
- Destructive actions are confirmed.
- Unavailable actions are hidden.
- The structure can accommodate report/block/share/mod actions without becoming cluttered.

## Validation

Run after implementation:

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test` if tests are added/changed.
- Manual `flutter run` checks:
  - Open post action sheet from feed and detail contexts.
  - Save/hide/edit/delete where available.
  - Confirm actions remain thumb-friendly and labels are clear.
  - Confirm delete still requires confirmation.

## Suggested skills / agents

- Use `@designer` for bottom-sheet layout, grouping, and mobile interaction polish.
- Reuse explorer session `exp-2 Check post edit implementation` for current post/comment action wiring if needed.
- Use `@fixer` for bounded migration after the sheet API is chosen.
