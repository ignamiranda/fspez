# Handoff: Inbox unread badge and mark-as-read

## Approved feature

Implement an **Inbox unread badge** and **mark messages as read when opened**.

## Current goal

Implement features to reach feature parity with the official Reddit mobile app, prioritizing mobile-app parity and mobile-quality UX.

## Existing implementation

Inbox already exists:

- Bottom navigation has Feed / Inbox / Account.
- `InboxScreen` supports All / Unread / Sent.
- Data layer fetches `/message/inbox`, `/message/unread`, `/message/sent`.
- Pagination, refresh, nested replies, unread dots, reply, and compose are implemented.
- `InboxRepository.markAsRead()` exists but UI does not call it.

## Scope

1. Add unread count/badge to the Inbox bottom navigation item.
2. Fetch or derive unread count from the unread inbox endpoint.
3. Mark a message/thread as read when the user opens/expands it.
4. Update local unread state and badge immediately after marking read.
5. Preserve current inbox tabs, pagination, reply, and compose behavior.

## Validation

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test` if tests are added/changed.
- Manual `flutter run`: authenticate, receive/open unread message, confirm badge decreases and unread styling clears.
