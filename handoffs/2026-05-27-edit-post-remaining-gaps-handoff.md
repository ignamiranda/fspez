# Handoff: Edit post remaining gaps

## Approved feature gap

Finish the remaining gaps around **editing submitted posts**.

The app already has post/comment body editing, but the feature was identified as partial rather than fully complete.

## Current goal

Implement features to reach feature parity with the official Reddit mobile app.

## Existing implementation

Already coded:

- `lib/src/presentation/screens/post_detail_screen.dart`
  - Enables edit on own post/comment.
  - Opens edit sheet.
  - Refreshes detail after save.
- `lib/src/presentation/widgets/edit_sheet.dart`
  - Existing edit UI and save flow.
- `lib/src/data/edit_notifier.dart`
  - Edit state and request wrapper.
- `lib/src/data/reddit_client.dart`
  - `editContent()` calls `/api/editusertext`.
- `lib/src/presentation/widgets/post_card.dart`
  - Edit entry exists in overflow menu.

## Remaining gap

The current implementation appears to edit **selftext/body only**. It does not appear to handle any additional editable post metadata or edge-case UX around non-editable posts.

Important Reddit caveat: post titles are generally not editable. Do not implement title editing unless current Reddit behavior proves it is actually supported for the target endpoint/account context.

## Suggested implementation scope

1. Audit current edit behavior for posts vs comments.
   - Confirm exactly which content types can be edited.
   - Confirm UI labels distinguish “Edit post body” vs “Edit comment” if needed.
2. Improve non-editable handling.
   - Hide or disable edit action for non-self/text posts if body editing is not meaningful.
   - Show clear feedback for archived/locked/deleted/non-editable failures.
3. Preserve draft text during edit failures.
4. Refresh updated post/comment in place after edit.
   - Ensure feed card, post detail header, and comment tree reflect changed body where relevant.
5. Add/update tests around edit visibility and failure behavior if practical.

## Deferred out of scope

- Title editing unless verified supported.
- Flair editing; separate flair handoff exists for submit-time flair selection.
- Media replacement/editing.
- Scheduled post edits or moderator edit tools.

## Validation

Run after implementation:

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test` if tests are added/changed.
- Manual `flutter run` check for own text post edit, own comment edit, and a non-editable/link/media post case.

## Suggested skills / agents

- Reuse explorer session `exp-2 Check post edit implementation` if more code discovery is needed.
- Use `@fixer` for bounded implementation after the desired remaining behavior is confirmed.
- Use `reddit-api-auth` only if endpoint/auth failures arise around `/api/editusertext`.
- Use `@oracle` if deciding whether additional edit metadata is real Reddit parity or impossible/YAGNI.
