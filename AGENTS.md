## Commands
- `flutter analyze` — lint + static analysis
- `flutter test` — unit tests only (no widget/integration)
- `flutter run` — Windows desktop (default target)
- `flutter build windows` — Windows release build

## Reporting feature work
- When a user-facing feature changes UI or Reddit-side behavior, include quick manual test steps in the final response: command to run, required account/data setup, exact UI path, and expected visible result. Do this even if automated tests passed.

## Before committing
- When new files are part of the change, remember that `git diff --stat` omits untracked files. Review `git status --short` and explicitly include intended new files in staging/diff review before committing.
- After any user-requested commit, end the final response with the next `handoffs/*.md` file to implement and a brief reason.
- When the user says `commit`, also perform the established cleanup workflow: delete the implemented handoff, run `/update-skills`, inspect status/diff/recent log, stage only intended files, commit, then report the next handoff.
- Run `dart format` only on Dart files. Do not pass YAML or other non-Dart files to `dart format`; use package/tool-specific formatting only when needed.

## Auto-trigger: `/reorder-todo` on TODO.md edits
Whenever you insert or remove a handoff entry in `TODO.md`, run `pwsh .agents/skills/reorder-todo/scripts/reorder-todo.ps1` to renumber. Never manually rewrite the entire file just to fix numbering.

## Architecture
- **Auth**: Cookie-only via WebView CDP (`Network.getCookies`, 10×500ms) → `GET /api/me` for modhash → username extraction (JS eval → API call → cookie heuristic). No OAuth. `AuthAcquirer` orchestrates.
- **State**: Riverpod (`StateNotifierProvider`, `FutureProvider.family`). Pagination via `CursorPaginatedNotifier` → `FeedPageNotifier` (cursor/after, loading). Optimistic updates via `OptimisticStateNotifier<K,V>` → `WriteOperationNotifier<V>`. `VoteNotifier` keeps optimistic on error; `SaveNotifier`/`HideNotifier` revert + rethrow. Settings via `AppSettingsNotifier` (persisted to `SharedPreferences` with `settings.*` keys).
- **Tabs**: `_MainShell` uses `IndexedStack` — all 3 tabs stay alive.
- **HTTP**: `RedditClient` wraps `http.Client`. `ApiEndpoint` enum selects per-endpoint headers. `get()` auto-appends `.json`.
- **No `build_runner`**: `freezed`/`json_serializable` listed but never run. Manual `Equatable`.
- **Entrypoint**: `lib/main.dart` — init `SharedPreferences`, override into `ProviderScope`, launch `FspezApp`. Also supports `FSPEZ_AUTOTEST_COMPOSE=1` autotest mode.
- **Key refs**: `CONTEXT.md` (domain language), `.opencode/memory/project.md` (project memory), `docs/adr/` (architecture decisions).

## Write operations
| Op | Endpoint | Modhash? | Domain |
|----|----------|----------|--------|
| Vote | `POST /api/vote` | No | www |
| Save/Unsave | `POST /api/save` | Yes | old |
| Delete | `POST /api/del` | No | www |
| Hide/Unhide | `POST /api/hide` | No | www |
| Comment | `POST /api/comment` | Yes | www |
| Compose | `POST /api/compose` | Yes | www |
| Submit | `POST /api/submit` | Yes | old |

### Save 403 prevention (any missing = 403)
- Full `rawCookie` string (all cookies `; `-joined), not just `reddit_session`
- `X-Modhash` header (from `GET /api/me → data.modhash`, NOT in Cookie)
- `old.reddit.com`, NOT `www.reddit.com`
- `X-Requested-With: XMLHttpRequest`, `Accept: */*`, `Content-Type: application/x-www-form-urlencoded; charset=UTF-8`
- Vote only needs `reddit_session` + form content type (no modhash, no old.reddit.com)

## Agent skills

### Issue tracker

Local markdown files under `.scratch/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Default five roles with default label strings. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout. See `docs/agents/domain.md`.

## Non-obvious gotchas
- **VideoPlayer stretches by default**: `VideoPlayer` from `video_player` sizes to `constraints.biggest` and draws the video texture stretched across its full bounds. It does NOT preserve aspect ratio on its own. Always wrap in `AspectRatio(aspectRatio: controller.value.aspectRatio)` — both inline and full-screen.
- **Feed sort**: Aggregate feeds (`/r/popular`, `/r/all`) must use path sort (`/r/popular/hot.json`), not `?sort=` query param. Handled by `_popularPathForSort()` in `feed_pagination.dart`.
- **Compose**: HTTP `RedditClient.compose()` often returns 403. WebView at `www.reddit.com/message/compose/` with CDP `Network.setCookie` seed is more reliable. `ComposeAutotestScreen` demonstrates; enable via `FSPEZ_AUTOTEST_COMPOSE=1` + `REDDIT_SESSION`.
- **PostDetailScreen**: Uses API-fetched `Post` from `postDetailProvider` for header, falls back to `widget.post` while loading. Matters when navigating from user profile comments.
- **Delete**: Confirmation dialog; button only shown when `post.author == currentUsername` (checked in `PostList`).
- **Linter**: `prefer_single_quotes`, `avoid_print`, `prefer_const_constructors`, `prefer_const_declarations`, `sort_child_properties_last`. `invalid_annotation_target` errors ignored.
- **Test**: `test/widget_test.dart` is a stub (placeholder `MyApp` counter test, not real fspez test). `mocktail` available for mocking.
- **Hide**: Optimistic — post removed from `visiblePosts` immediately, reappears on API error.
- **Reddit URL entity encoding**: URL fields from Reddit API (`icon_img`, `community_icon`, `thumbnail`, `banner_img`, `banner_background_image`, `sr_detail.icon_img`, media URLs) contain `&amp;` entities. Always decode via `_cleanUrl()` / `url.replaceAll('&amp;', '&')` before passing to Flutter widgets. A raw `&amp;` URL causes 403s when Flutter requests it literally.
- **PostCard is ConsumerStatefulWidget**: `PostCard` reads `appSettingsProvider` for blur/reveal state. Tests must wrap in `ProviderScope` with `sharedPrefsProvider` override.
- **RadioGroup<T>**: New Flutter 3.32+ API. Use `RadioGroup<T>(groupValue: ..., onChanged: ..., child: ...)` wrapping `Radio<T>(value: ...)` or `RadioListTile<T>(value: ...)`. Do NOT use deprecated `groupValue`/`onChanged` params on individual radios.
- **AppThemeMode**: Custom enum (not Flutter's `ThemeMode`) with 4 values: system, light, dark, amoled. `toThemeMode()` maps dark/amoled both to `ThemeMode.dark`; `FspezApp` switches `darkTheme` reference based on mode.
