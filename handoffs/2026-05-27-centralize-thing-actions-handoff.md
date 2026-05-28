# Handoff: Centralize Reddit thing actions behind use-case services

## Approved architecture improvement

Centralize Reddit post/comment/moderation actions behind focused use-case services instead of letting screens/widgets/notifiers directly coordinate endpoint quirks, optimistic state, and UI recovery behavior.

## Current goal

Implement features to reach feature parity with the official Reddit mobile app.

## Why this architecture improvement

Feature parity is adding many related Reddit “thing actions”: vote, save, hide, delete, edit, report, block, mute, crosspost, moderation approve/remove/ban, removal reasons, user notes, etc.

Without a coordination layer, each feature tends to re-learn:

- Which Reddit domain to use (`www.reddit.com` vs `old.reddit.com`).
- Whether modhash is required.
- Which optimistic updates should persist on failure versus revert.
- How to refresh affected feed/detail/profile/inbox state.
- How to map low-level API errors into user-facing messages.

A thin use-case layer can reduce duplication, keep widgets smaller, and make future parity features faster and safer to implement.

## Existing related implementation

Inspect these areas first:

- `lib/src/data/reddit_client.dart`
  - Low-level Reddit endpoint methods and domain/header quirks.
- `lib/src/data/write_operation_notifier.dart`
  - Shared write operation state pattern, if present.
- `lib/src/data/optimistic_state_notifier.dart`
  - Shared optimistic update behavior, if present.
- `lib/src/data/vote_notifier.dart`
  - Vote optimistic semantics; project notes say vote keeps optimistic state on error.
- `lib/src/data/save_notifier.dart`
  - Save optimistic semantics; project notes say save reverts and rethrows on error.
- `lib/src/data/hide_notifier.dart`
  - Hide optimistic semantics; project notes say hide reverts and rethrows on error.
- `lib/src/data/edit_notifier.dart`
  - Edit request wrapper.
- `lib/src/presentation/widgets/post_card.dart`
  - Current post action menu and callbacks.
- `lib/src/presentation/widgets/feed_screen_scaffold.dart`
  - Feed-level action wiring.
- `lib/src/presentation/screens/post_detail_screen.dart`
  - Detail/comment action wiring.
- `lib/src/presentation/widgets/comment_tree.dart`
  - Comment action wiring.

Relevant project architecture notes:

- Cookie-only auth via WebView CDP and `/api/me` modhash.
- `RedditClient` wraps `http.Client`.
- `ApiEndpoint` enum selects per-endpoint headers.
- `get()` auto-appends `.json`.
- Write operations have different domain/modhash requirements.
- Riverpod is the state layer.
- No `build_runner`; prefer manual simple classes.

## Suggested target shape

Keep this as a thin coordination layer, not a large framework.

Possible services:

- `PostActionsService`
  - vote, save/unsave, hide/unhide, delete, edit body, copy/share later, report later.
- `CommentActionsService`
  - vote if comments support it, reply coordination, edit body, delete, report later.
- `ModerationActionsService`
  - approve/remove/spam/ban/removal reasons/user notes as those handoffs are implemented.

Responsibilities:

- Call `RedditClient`/repositories.
- Apply consistent optimistic semantics through existing notifier abstractions.
- Return small result objects or throw typed/domain errors.
- Avoid importing Flutter UI widgets.
- Avoid owning navigation or snackbar display.

Non-goals:

- Do not replace `RedditClient` as the low-level HTTP boundary.
- Do not create a huge generic “action bus”.
- Do not move every read/fetch path into services.
- Do not block feature delivery with a full clean architecture rewrite.

## Suggested implementation scope

Smallest safe vertical slice:

1. Audit existing post/comment action flows and document current call graph.
2. Pick one high-value cluster first, likely post save/hide/delete/edit from `PostCard` + `PostDetailScreen`.
3. Introduce one focused service with Riverpod provider wiring.
4. Migrate callers without changing user-visible behavior.
5. Add/update tests around service behavior and optimistic failure semantics.
6. Leave TODO-free seams for future report/block/mod action handoffs to plug in.

## Technical discovery needed

Before editing, inspect:

- Existing provider names and dependency injection style.
- Whether action notifiers are currently global, keyed by post ID, or owned by widgets.
- How feed/detail refreshes after write operations today.
- Which actions already have tests and should remain behavior-compatible.
- Whether error handling is duplicated in UI and can be standardized without changing copy.

## Acceptance criteria

- At least one existing action cluster is routed through a use-case service.
- No user-facing behavior regressions for migrated actions.
- Existing optimistic semantics are preserved:
  - Vote keeps optimistic state on error.
  - Save/hide revert and rethrow on error.
- UI widgets become thinner or at least no more coupled to endpoint quirks.
- New service code has unit tests or migrated existing tests.
- `RedditClient` remains the only direct HTTP boundary.

## Validation

Run after implementation:

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test`.
- Manual `flutter run` smoke check:
  - Vote/save/hide/delete/edit a post where supported.
  - Confirm feed/detail state remains consistent.
  - Confirm error handling still reverts or persists according to existing semantics.

## Suggested skills / agents

- Use `improve-codebase-architecture` if doing a broader architecture pass before implementation.
- Reuse explorer session `exp-2 Check post edit implementation` for current post/detail/client context if more discovery is needed.
- Use `@oracle` for review before migrating many call sites; this is an architecture-affecting change.
- Use `@fixer` for bounded migration once the service shape and first action cluster are chosen.
