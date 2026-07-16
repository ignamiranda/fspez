# Council Critique — fspez v0.1.0+1

**Date**: 2026-07-15
**Method**: 7 independent sub-agents (Architecture, Error Handling, Testing, Security, Code Quality, HTTP/Data Layer, Riverpod State Management)
**Verdict**: The app delivers — but with systemic architectural debt that compounds with every feature.

---

## Composite Scorecard

| Dimension | Score | Trend |
|-----------|:-----:|:-----:|
| 🏛️ Architecture & Layers | **3/10** | 🔴 Getting worse — every new screen adds to the presentation→data leak |
| 💥 Error Handling & Resilience | **3/10** | 🔴 Critical — no timeouts, silent failures everywhere |
| 🧪 Testing Quality & Coverage | **4/10** | 🟡 Flat — 270 green tests but critical paths uncovered |
| 🔒 Security & Auth | **5/10** | 🟡 Flat — core auth is solid but 4 write endpoints miss CSRF |
| 🧹 Code Quality & Maintainability | **6.5/10** | 🟢 Improving — low TODOs, but complexity hotspots remain |
| 📡 HTTP / Data Layer | **4/10** | 🟡 Flat — circular import, fragmented clients, fragile parsing |
| 🔄 Riverpod State Management | **4.5/10** | 🔴 Getting worse — memory leaks grow with every new family provider |
| **Weighted Composite** | **4.2/10** | 🔴 Systemic |

Note: This is not a judgement of *does the app work?* — it does, 270 tests pass. This is a judgement of *how well will this survive 10 more features and 3 more developers?* The answer: poorly, without structural investment.

---

## 🔴 Critical Issues (fix now, or they compound)

### 1. Every screen imports `data/` directly — the architecture has no abstraction boundary

**Severity**: Architectural collapse in slow motion
**Finding**: All 13 of 16 screens and 11 of 31 widgets import from `lib/src/data/`. Screens construct HTTP field names (`kind`, `sr`, `uh`), pass session cookies around by hand, and instantiate data-layer orchestrators (`AuthAcquirer`) in `initState`.

**Example**: `submit_screen.dart:90-94`
```dart
final fields = <String, String>{
  'kind': 'self',
  'sr': subreddit,
  'title': title,
  'uh': account.sessionCookie.modhash ?? '',
};
```
The screen knows Reddit's HTTP form field names. This is feature envy at the architectural level — the submit screen is a glorified HTTP client.

**Fix direction**: Extract all HTTP field construction into `SubmitNotifier`. Add a `FeedRepository` / `CommentRepository` interface layer. Move the `AuthAcquirer` instantiation to a provider.

### 2. ADR 0004 explicitly violated — one-shot actions use singleton providers

**Severity**: State leaks across screen lifetimes
**Finding**: ADR 0004 mandates local `StateNotifier` instances per screen for one-shot operations (compose, submit, edit). The code implements exactly the **rejected** approach — singleton `StateNotifierProvider`s. `/docs/adr/0004-one-shot-actions-as-local-state-notifiers.md` contains a detailed rationale, and the code does the opposite.

**Evidence**: 
- `submitProvider` stores `selectedImage`, `galleryFiles`, `selectedVideo` — these survive when the user navigates away and back
- No `reset()` call in any screen's `dispose()`
- `composeProvider` and `editProvider` are also global singletons

### 3. No network timeouts anywhere — app hangs indefinitely

**Severity**: Catastrophic UX on flaky networks
**Finding**: Zero `TimeoutException` handling. Zero `http.Client` timeout configuration. Every `http.Client.get()/post()/put()` call blocks forever on a hanging TCP connection. The S3 media upload (`media_client.dart:46-50`) also has no timeout.

Zero references to `SocketException` or `TimeoutException` in the codebase (except one fragile `e.toString().contains('SocketException')` string check in `auth_webview_screen.dart`).

### 4. Vote optimistic state permanently wrong on API failure

**Severity**: Data integrity bug
**Finding**: `post_actions_service.dart:47` — vote errors use `WriteErrorPolicy.keepOptimistic` with a `.catchError((_) {})` swallow. If the vote API fails, the UI shows the voted state **permanently** (until feed re-fetch). No visual feedback. No rollback. No recovery signal.

### 5. Zero `autoDispose` on any provider — memory leaks on every navigation

**Severity**: Monotonically growing memory
**Finding**: Zero instances of `.autoDispose` in `lib/`. Every `.family` provider (`feedPageProvider`, `postDetailProvider`, `searchPostsProvider`, `userProfileProvider`) creates permanent entries. Visit 5 subreddits with 3 sorts + 3 searches + 10 post details = 34 provider instances that never die.

The four global optimistic maps (`voteProvider`, `saveProvider`, `hideProvider`, `deleteProvider`) also grow unbounded. Vote on 500 posts = 500 map entries, never evicted.

### 6. HTTP transport layer has zero tests — blind confidence in the backbone

**Severity**: Untested = untrustworthy
**Finding**: `http_transport.dart` (163 lines, 6 request methods + header construction for 6 `ApiEndpoint` variants) has **zero direct tests**. All data-layer tests mock `http.Client` at the socket level — they bypass `HttpTransport` entirely. The `_headersFor()` switching logic, `handleJsonResponse()` error handling, URL construction — none of it is verified.

### 7. SubmitNotifier (345 lines, most complex notifier) has zero tests

**Severity**: Untested = untrustworthy
**Finding**: Post submission with image/video/gallery upload, flair debounce, file I/O, S3 upload orchestration — none of it tested. A regression in the submit flow escapes to production silently.

---

## 🟡 Serious Issues (fix before the next feature)

### 8. 5 separate implementations of the same form-POST pattern

**Severity**: Maintainability drag
**Finding**: `InteractionClient._postForm`, `AccountClient._postForm`, `SubmitClient.submit`, `MessageClient.compose`, `InboxRepository._fetch` all implement the same `Uri(queryParameters:).query` form-encoding with different success-detection strategies. Three different protocols: check JSON body, check content-type header, check `json.errors`. Extract to `HttpTransport`.

### 9. Circular import between `http_transport.dart` and `reddit_client.dart`

**Severity**: Testability blocker
**Finding**: `http_transport.dart` imports `reddit_client.dart` (for `RedditApiException`) and vice versa. Dart's deferred loading hides this, but it's a design smell — move `RedditApiException` to its own file.

### 10. 4 write endpoints missing X-Modhash CSRF protection

**Severity**: Security gap on cookie-only auth
**Finding**: `ApiEndpoint.form` (used by vote, hide, unhide, report) does NOT include `X-Modhash` header. All other write endpoints do. This is a 5-minute fix — add `X-Modhash` to the `form` case in `http_transport.dart:_headersFor()`.

### 11. `handleJsonResponse` silently discards non-map JSON

**Severity**: Silent data corruption
**Finding**: `http_transport.dart:84-94` — when Reddit returns a JSON array (common for comment feeds), the method returns `{}` because it only accepts `Map<String, dynamic>`. The data is silently lost. Every consumer that calls `get()` expecting a list gets an empty map instead.

### 12. `account_repository.dart:loadAll()` crashes on corrupted JSON

**Severity**: Data loss on startup
**Finding**: `jsonDecode(json)` without try/catch. If secure storage contains corrupted bytes (known issue — PR #25), `loadAll()` throws `FormatException` or `TypeError` at the `as String` casts. The account init path loses all accounts.

### 13. No eviction strategy in FeedCache — keys accumulate in SharedPreferences forever

**Severity**: Performance decay
**Finding**: `FeedCache` (SharedPreferences-backed) has no TTL, no LRU, no size limit. The only eviction is `clearForAccount` — O(n) scan over the entire SharedPreferences namespace.

### 14. Coarse-grained `ref.watch` on global optimistic maps triggers full-screen rebuilds

**Severity**: Performance drag
**Finding**: `feed_screen_scaffold.dart:36-41` watches `voteProvider`, `saveProvider`, `hideProvider` — all `Map<String, V>` providers. Every vote/save/hide anywhere in the app rebuilds every feed screen and post detail screen. No `select` is used to scope to the relevant key.

### 15. 5 near-identical search tab widgets — massive copy-paste

**Severity**: Maintenance liability
**Finding**: `search_screen.dart` has 5 tab widget classes that are 80% identical — same `watch provider → check loading → check error → RefreshIndicator → ListView.builder` pattern. Only the provider type and item card differ.

### 16. `account_screen.dart` uses `List<dynamic>` / `dynamic` instead of `List<Account>` / `Account`

**Severity**: Type safety abandoned
**Finding**: `_buildLoggedIn(BuildContext, List<dynamic>, dynamic)` — the `Account` model exists but the screen bypasses it entirely. This hides type errors that would be caught at compile time.

### 17. Post detail screen has no retry button on error — dead-end UX

**Severity**: User abandonment
**Finding**: `post_detail_screen.dart:173-188` — the error state shows a generic "Failed to load post" with the error detail discarded and no retry action. The user must navigate back and re-enter.

---

## 🟢 Minor Issues (fix when convenient)

- `universal_html` in pubspec.yaml — imported nowhere, dead dependency weight
- `markdown` package undeclared in pubspec.yaml — transitively available, breaks on dep shift
- `ApiListing.fromListing` — dead factory that just delegates
- `FeedKind.saved` — TODO in code says it should be removed
- `app_theme_mode.dart` imports Flutter from the domain layer — trivial move
- `MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW` in WebView — tighten to `NEVER_ALLOW`
- WebView has no URL whitelist — user can navigate anywhere from login flow
- Session cookie hardcodes 365-day expiry — doesn't read Reddit's actual `Set-Cookie`
- `inboxUnreadCountProvider` — unnecessary indirection (one-line `select`)
- `BlockActionNotifier.unblock` doesn't use `write()` despite `block()` doing so
- Video player `FeedMediaTile` infinite layout bug fixed in HEAD — 2d434d5
- `RedditClient` accepts two different constructor injection points for the same dependency

---

## Thematic Summary

### What the app does well
- **Domain layer is pure** — zero imports from data or presentation
- **`HttpTransport` is a deep module** — good encapsulation of request/response handling (despite the circular import)
- **`PostActionsService` is a clean facade** — optimistic update orchestration in one place
- **`PaginatedNotifier` + `OptimisticStateNotifier`** — solid generic abstractions
- **Zero FIXME/HACK/XXX/todo debt** (1 TODO only) — the team removes or addresses
- **Mocktail, not mockito** — correct choice
- **Hand-written models, no codegen** — consistent with the project's ethos

### What needs structural investment

**1. The architecture has no guardrails.** Data-layer types leak into every screen, widgets call repositories directly, screens construct HTTP bodies. This isn't one or two files — it's the entire presentation layer. The project needs either (a) a formal repository interface layer, or (b) a strict "screens only touch providers, not data-layer classes" convention enforced by review.

**2. Error handling is treated as optional.** 16+ silent `catch (_)` blocks, zero timeouts, zero SocketException handling, zero 429 awareness, one global error boundary (none), one vote-state-rollback for all the optimistic updates. A data-heavy network app cannot afford this.

**3. Testing is wide but shallow.** 270 tests that pass, but the HTTP backbone, the submit flow, the media upload, and most domain models are uncovered. The mock boundary is at the socket level — not the transport level — so tests verify Dart's `http.Client` works correctly, not that the app's request construction is correct.

**4. State management leaks memory proportional to feature usage.** Zero `autoDispose`, unbounded global maps, screen-scoped state stored globally. On a desktop app this might be tolerable; on mobile with RAM constraints it will bite.

**5. The data layer has six clients but one pattern.** Five separate implementations of form-encoded POST. Three different success-detection strategies. A circular import. Silent data loss on non-map JSON responses. This should be refactored into a single consistent abstraction.

---

## Priority Action Plan — Post-Council Status

| # | Fix | Effort | Status | Dimension |
|---|-----|--------|--------|-----------|
| 1 | Add `X-Modhash` to `ApiEndpoint.form` | 5 min | ✅ Done | Security |
| 2 | Set timeouts on all `http.Client` calls | 15 min | ✅ Done | Error Handling |
| 3 | Extract `RedditApiException` to own file | 5 min | ✅ Done (also extracted `ApiEndpoint`) | Data Layer |
| 4 | Add `autoDispose` to all `.family` providers | 30 min | ✅ Done | State Mgmt |
| 5 | Add `select` to vote/save/hide watchers | 20 min → 1 hr | ✅ Done (PostDetailScreen split) | State Mgmt |
| 6 | Write tests for `http_transport.dart` | 2-3 hr | ⏸️ Deferred | Testing |
| 7 | Write tests for `submit_notifier.dart` | 3-4 hr | ⏸️ Deferred | Testing |
| 8 | Extract unified form-POST utility | 1 hr | ✅ Done | Data Layer |
| 9 | Guard `account_repository.loadAll()` against FormatException | 10 min | ✅ Done | Error Handling |
| 10 | Add `ErrorWidget.builder` / `FlutterError.onError` to main.dart | 15 min | ✅ Done | Error Handling |
| 11 | Replace `catch (_)` with `catch (e, st)` + `debugPrint` | 1 hr | ✅ Done (19 blocks) | Error Handling |
| 12 | Extract search tab duplication | 2-3 hr | ⏸️ Deferred | Code Quality |
| 13 | Convert `submit_screen.dart` HTTP field construction to notifier | 1 hr | ✅ Done | Architecture |
| 14 | Tighten WebView: mixed content → NEVER, add URL whitelist | 30 min | ✅ Done | Security |

**Council session completed 2026-07-15**: 10 of 14 fixes applied across 8 dimensions. 0 new analyze issues. 270/270 tests passing throughout. 16 files modified across the codebase.
