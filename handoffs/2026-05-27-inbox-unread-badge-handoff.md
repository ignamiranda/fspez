# Handoff: Inbox unread badge feature

## Current goal

Implement features to reach feature parity with the official Reddit mobile app.

## User request sequence

1. User set active goal: `implement features to reach feature parity with the official reddit mobile app`.
2. User asked: `suggest a feature`.
3. Suggested feature: **inbox notifications + unread badge**.
4. User said: `implement`.
5. A todo list was started for a first vertical slice:
   - Inspect app navigation, Reddit client, auth/state patterns for inbox integration — in progress.
   - Implement unread inbox count provider/client method and nav badge UI — pending.
   - Run formatting/static analysis/tests relevant to changes — pending.
6. Before code inspection/implementation proceeded, user changed request to: write this handoff into project directory folder `/handoffs/` with a unique filename.

## Proposed feature slice

Build **unread inbox count badge only** as the first vertical slice toward full Reddit inbox parity.

Expected scope:

- Add a Reddit API client method to fetch unread inbox items, likely from `/message/unread.json`.
- Compute unread count from response listing children.
- Add Riverpod provider/state for unread inbox count.
- Display count badge on existing main navigation inbox/messages destination, or add one if no inbox destination exists.
- Add refresh behavior on app resume/tab selection if consistent with existing app patterns.
- Keep the feature small; defer full message list, mentions, mark-read actions, and pagination to later slices.

## Repository context to preserve

Important project instructions from `AGENTS.md`:

- Commands:
  - `flutter analyze`
  - `flutter test`
  - `flutter run`
  - `flutter build windows`
- Entrypoint: `lib/main.dart`.
- State: Riverpod with `StateNotifierProvider`, `FutureProvider.family`.
- Main shell uses `IndexedStack`; all 3 tabs stay alive.
- HTTP: `RedditClient` wraps `http.Client`; `get()` auto-appends `.json`.
- Auth is cookie-only via WebView CDP; `GET /api/me` gets modhash.
- No `build_runner`; use manual models / `Equatable` patterns.
- Linter preferences include `prefer_single_quotes`, `avoid_print`, `prefer_const_constructors`, `prefer_const_declarations`, `sort_child_properties_last`.
- `test/widget_test.dart` is a stub, not a useful app test.

Key docs/refs:

- `CONTEXT.md`
- `.opencode/memory/project.md`
- `docs/adr/`
- `AGENTS.md`

## Suggested next steps

1. Inspect navigation/main shell and current tab definitions.
2. Inspect `RedditClient` and existing listing/parsing methods.
3. Inspect auth providers/current user/client provider wiring.
4. Implement the smallest unread count path:
   - client method
   - count provider
   - nav badge UI
5. Run `dart format` on touched Dart files.
6. Run `flutter analyze`; run `flutter test` if any tests are added/changed.

## Suggested skills / agents

- Use `@explorer` first for broad codebase discovery of navigation, providers, and `RedditClient` methods.
- Use `@fixer` for bounded multi-file implementation after paths and patterns are known.
- Use `reddit-api-auth` only if write-style Reddit endpoint/auth problems arise; likely not needed for read-only `/message/unread.json`.
- Use `@oracle` only if implementation reveals architectural ambiguity about global app notifications/badges.

## Current status

No implementation files have been changed for the inbox feature. This handoff file is the only intended artifact from the latest request.
