## Commands
- `flutter analyze` — lint + static analysis (all errors)
- `flutter test` — unit tests only (no widget/integration tests yet)
- `flutter run` — runs on Windows desktop (default target)
- `flutter build windows` — Windows release build

## Architecture
- **`lib/src/data/`** — `RedditClient` (HTTP wrapper, now includes save/unsave), repositories (feed, comment, vote, save, subreddit), notifiers (`OptimisticStateNotifier` base class + `VoteNotifier`, `SaveNotifier`, `ActiveAccountNotifier`), parsers (feed, comment, cookie), `providers.dart` (all Riverpod providers), `session_store.dart` (WebView cookie polling), `cdp_cookie_provider.dart` (public CookieProvider adapter)
- **`lib/src/domain/`** — models (`Post`, `Comment`, `Feed`, `Account`, `SessionCookie`, `Subreddit`), enums (`FeedSort`, `VoteDirection`). Pure data objects, no logic.
- **`lib/src/presentation/`** — `app.dart` (MaterialApp + bottom nav), screens (feed, inbox, account, auth_webview, post_detail, saved, search, subreddit_feed), widgets (`PostCard`, `CommentTree`, `PostList`), utils (`format_utils.dart`, `interaction_helpers.dart`)
- **Entrypoint**: `lib/main.dart` — initializes `SharedPreferences`, overrides into `ProviderScope`, launches `FspezApp`
- **Riverpod**: All state managed via `StateNotifierProvider` (vote, save, active account) and `FutureProvider.family` (feed, post detail)
- **StateNotifier pattern**: `VoteNotifier` / `SaveNotifier` extend `OptimisticStateNotifier<String, V>` which provides `optimisticSet()` / `optimisticRevert()` / `effective()`. Both use optimistic updates; SaveNotifier reverts on any error and rethrows, VoteNotifier keeps optimistic state on error (swallows it).
- **Auth**: No OAuth. `AuthWebViewScreen` opens WebView → user logs in → JS injection extracts `reddit_session` from CDP `Network.getCookies` → polls every 500ms up to 10 attempts → stores `SessionCookie` with `rawCookie` (all cookies) and `modhash` in `SharedPreferences` via `AccountRepository`

## Save feature: Modhash requirement
Save/unsave goes through `RedditClient.save()`/`RedditClient.unsave()` which hit `https://old.reddit.com/api/save` with browser-headers. Callers don't need to handle old.reddit.com specifics. Requirements:
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
| `lib/src/data/reddit_client.dart` | HTTP wrapper, now includes save/unsave for `old.reddit.com` |
| `lib/src/data/providers.dart` | All Riverpod providers |
| `lib/src/data/session_store.dart` | `CookieProvider` abstract class, `SessionStore.acquire()` polling |
| `lib/src/data/save_repository.dart` | Delegates to `RedditClient` for save/unsave |
| `lib/src/data/save_notifier.dart` `vote_notifier.dart` | Optimistic state with revert-on-error via `OptimisticStateNotifier` |
| `lib/src/data/optimistic_state_notifier.dart` | Base class for optimistic-update `StateNotifier` |
| `lib/src/data/account_notifier.dart` | `ActiveAccountNotifier` |
| `lib/src/data/cdp_cookie_provider.dart` | Public `CookieProvider` via CDP `Network.getCookies` |
| `lib/src/presentation/screens/auth_webview_screen.dart` | WebView login flow, CDP cookie extraction, modhash fetch |
| `lib/src/presentation/widgets/post_list.dart` | Shared `PostList` widget for PostCard lists |
| `lib/src/presentation/utils/interaction_helpers.dart` | Shared `handleVote()`/`handleSave()` |
| `lib/src/presentation/utils/format_utils.dart` | Shared `formatCount()`/`timeAgo()` |
| `docs/adr/0001-cookie-only-auth.md` | Explains why no OAuth (API pricing changes) |
| `.opencode/skills/reddit-api-auth/SKILL.md` | Skill: debugging modhash-based auth 403s |
| `.opencode/skills/learn/SKILL.md` | Skill: extract reusable knowledge into new/updated skills |
| `opencode.json` | Custom `/learn` command to extract skills from sessions |

## Constraints
- No OAuth, no Reddit app registration — all auth via session cookies
- Save endpoints are stricter than vote (modhash + old.reddit.com + full cookie string)
- SDK `^3.4.0`, Flutter `^3.22.0`, `flutter_inappwebview` for WebView, `shared_preferences` for persistence
- No `build_runner` / code generation output in repo (freezed/json_serializable listed but not run)
- Test file `test/data/cookie_parser_test.dart` has a pre-existing failing test (`extractUsername falls back to generic name`)
