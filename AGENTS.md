## Commands
- `flutter analyze` — lint + static analysis (all errors)
- `flutter test` — unit tests only (no widget/integration tests yet)
- `flutter run` — runs on Windows desktop (default target)
- `flutter build windows` — Windows release build

## Architecture
- **`lib/src/data/`** — `RedditClient` (HTTP wrapper), repositories (feed, comment, vote, save, subreddit), notifiers (vote, save), parsers (feed, comment, cookie), `providers.dart` (all Riverpod providers), `session_store.dart` (WebView cookie polling)
- **`lib/src/domain/`** — models (`Post`, `Comment`, `Feed`, `Account`, `SessionCookie`, `Subreddit`), enums (`FeedSort`, `VoteDirection`). Pure data objects, no logic.
- **`lib/src/presentation/`** — `app.dart` (MaterialApp + bottom nav), screens (feed, inbox, account, auth_webview, post_detail), widgets (`PostCard`, `CommentTree`)
- **Entrypoint**: `lib/main.dart` — initializes `SharedPreferences`, overrides into `ProviderScope`, launches `FspezApp`
- **Riverpod**: All state managed via `StateNotifierProvider` (vote, save, active account) and `FutureProvider.family` (feed, post detail)
- **StateNotifier pattern**: `VoteNotifier` / `SaveNotifier` use optimistic updates with revert on error + rethrow
- **Auth**: No OAuth. `AuthWebViewScreen` opens WebView → user logs in → JS injection extracts `reddit_session` from CDP `Network.getCookies` → polls every 500ms up to 10 attempts → stores `SessionCookie` with `rawCookie` (all cookies) and `modhash` in `SharedPreferences` via `AccountRepository`

## Save feature: Modhash requirement
`/api/save` and `/api/unsave` bypass `RedditClient` and hit `https://old.reddit.com/api/save` directly with browser-headers via `package:http`. They require ALL of:
- Domain: `old.reddit.com` (NOT `www.reddit.com`)
- Cookie: full `rawCookie` string (CDP all-cookies join), not just `reddit_session`
- `X-Modhash` header (NOT in Cookie) — extracted via `GET /api/me → data.modhash` during login in `_fetchModhash()`, stored on `SessionCookie.modhash`
- `X-Requested-With: XMLHttpRequest`, `Accept: */*`, `Content-Type: application/x-www-form-urlencoded; charset=UTF-8`

Vote (`/api/vote`) works with just `reddit_session` + form-encoded content type (no modhash, no old.reddit.com).

## Debugging Reddit API 403s
Use `controller.callDevToolsProtocolMethod('Runtime.evaluate', {awaitPromise: true, returnByValue: true, expression: '...'})` to make a same-origin `fetch()` from within the WebView. Override `XMLHttpRequest.prototype.setRequestHeader` to capture exact browser request headers.

## Key files
| File | Purpose |
|------|---------|
| `lib/src/data/reddit_client.dart` | HTTP wrapper, base `www.reddit.com`, appends `.json` to GET paths |
| `lib/src/data/providers.dart` | All Riverpod providers, `ActiveAccountNotifier` |
| `lib/src/data/session_store.dart` | `CookieProvider` abstract class, `SessionStore.acquire()` polling |
| `lib/src/data/save_repository.dart` | Direct HTTP to `old.reddit.com`, writes debug log to `save_debug.log` |
| `lib/src/presentation/screens/auth_webview_screen.dart` | WebView login flow, CDP cookie extraction, modhash fetch |
| `lib/src/data/save_notifier.dart` `vote_notifier.dart` | Optimistic state with revert-on-error |
| `docs/adr/0001-cookie-only-auth.md` | Explains why no OAuth (API pricing changes) |
| `.opencode/skills/reddit-api-auth/SKILL.md` | Skill: debugging modhash-based auth 403s |
| `.opencode/skills/learn/SKILL.md` | Skill: extract reusable knowledge into new/updated skills |
| `opencode.json` | Custom `/learn` command to extract skills from sessions |

## Auto-trigger: `/learn` on commit
Whenever the user says "commit" (or "git commit", "time to commit", etc.), automatically run the `/learn` command first to extract reusable knowledge from the session before the commit is performed.

## Constraints
- No OAuth, no Reddit app registration — all auth via session cookies
- Save endpoints are stricter than vote (modhash + old.reddit.com + full cookie string)
- SDK `^3.4.0`, Flutter `^3.22.0`, `flutter_inappwebview` for WebView, `shared_preferences` for persistence
- No `build_runner` / code generation output in repo (freezed/json_serializable listed but not run)
- Test file `test/data/cookie_parser_test.dart` has a pre-existing failing test (`extractUsername falls back to generic name`)
