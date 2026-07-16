# fspez — agent guide

## 🔴 Non-negotiable

**No API key use ever.** The app must never embed, ship, or require an API key from any service. This includes hardcoded keys, build-time injection, or runtime requirements.

Exception: local dev/debugging may use a `REDDIT_SESSION` env var (session cookie token, never committed). Session cookies stored via `flutter_secure_storage`, not `SharedPreferences`.

## Architecture

Cookie-based Reddit client — no OAuth, no app registration. WebView login flow captures a session cookie.

```
lib/
├── main.dart                  ← entrypoint (ProviderScope, SharedPrefs + SecureStorage overrides)
├── src/
│   ├── data/                  ← HTTP transport, RedditClient, notifiers, repositories, providers
│   ├── domain/                ← models (EquatableMixin hand-written), enums
│   └── presentation/          ← screens, widgets, theme (Material 3), utils
```

**Auth gate**: `_AppGate` → `LoginScreen` or `_MainShell`. Shell: `IndexedStack` with 3 tabs (Feed, Inbox, Account), bottom `NavigationBar`.

**HTTP layer**: `HttpTransport` wraps `http.Client`. Uses three base URLs:
- `old.reddit.com` (read: `*.json` suffix, write: `/api/del`, `/api/save`)
- `www.reddit.com` (write: `/api/comment`, `/api/submit`, `/api/media/asset.json`, etc.)

6+ `ApiEndpoint` variants — each sets headers differently (User-Agent, Content-Type, Cookie, X-Modhash). `mediaUpload` includes X-Modhash header.

**Media upload (image/video/gallery)**: two-step via `MediaUploadClient`:
1. `POST /api/media/asset.json` → `UploadLease` (asset\_id, upload\_url = S3 presigned)
2. `PUT` raw bytes to `upload_url` with `Content-Type: image/*` or `video/*`

**Flair**: `SubmitNotifier` caches options per subreddit, 300ms debounce on subreddit field input.

**State**: Riverpod. Optimistic UI via `OptimisticStateNotifier` for vote/save/hide. Feed cache with stale-while-revalidate via `FeedCache`.

## Commands

```sh
flutter pub get                         # handles pubspec + flutter_inappwebview_windows dep override
flutter analyze                         # runs pub get first if needed
flutter analyze --no-pub                # CI uses --no-pub (must already have deps)
flutter test                            # 239 tests, all pass
flutter run -d windows                  # Windows dev (start.bat shorthand)
```

No codegen, no build\_runner, no freezed. All models hand-written.

## Testing quirks

- **mocktail** for mocks (not mockito)
- `AccountRepository` tests use `FakeSecureStorage` (custom in-memory fake)
- `SessionAcquirer` tests exercise polling pattern (cookie acquisition from WebView)
- No integration tests — WebView login can't be automated
- Autotest: `FSPEZ_AUTOTEST_COMPOSE=1` env var + `REDDIT_SESSION` env var → launches `ComposeAutotestScreen` directly (bypasses normal app flow)
- UI widget tests use standard `MaterialApp` wrappers with Riverpod `ProviderScope`

## Config quirks

- `dependency_overrides` in `pubspec.yaml`: `flutter_inappwebview_windows` → local `third_party/` path (vendored Windows WebView plugin fork)
- `analysis_options.yaml`: excludes `third_party/**`, silences `invalid_annotation_target` (legacy from removed freezed)
- `analysis_options.yaml` linter rules: `prefer_const_constructors`, `prefer_const_declarations`, `avoid_print`, `prefer_single_quotes`, `sort_child_properties_last`

## CI/CD (`.github/workflows/build.yml`)

On push/PR to `master`: `pub get → analyze --no-pub → test → build apk --release → github release`

Conditional keystore signing step (requires `KEYSTORE_BASE64` secret). Release tag: `v{version}+{run_number}`.

## Domain vocabulary

Use terms from `CONTEXT.md`: **User** (physical human), **Account** (Reddit identity with cookie), **InboxItem** (DM or CommentNotification union), **Feed** (any paginated post card list), **Subreddit** (code) / community (UI text), **Draft** (local unsubmitted content). Avoid: Person, Message (for inbox items), Thing, Community (in code), Listing.

## Session postmortem: hardened patterns

### No silent deferral — verification step

The global AGENTS.md already prohibits silent deferral ("state the estimate and trade-off, then ask"). If you violated it once, more text on the same rule won't help — the problem is compliance, not presence.

**Before proposing to defer or skip any item** (especially from a critique or review outcome):
1. Search the global AGENTS.md for the phrase "No silent deferral"
2. Quote it verbatim to the user
3. Then state: effort estimate + trade-off + explicit ask

### Read before edit

Before calling `edit()` with an `oldString` parameter for changes to existing code: Read the target file, capture the exact current text for the `oldString` parameter. Do not reconstruct it from memory or from a prior read.

If edit() fails with "oldString not found": Read the file again to verify current content before retrying.

## Agent skills

### Issue tracker

Issues are tracked on GitHub. See `docs/agents/issue-tracker.md`.

### Triage labels

Five state labels with defaults. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout — one CONTEXT.md + docs/adr/ at root. See `docs/agents/domain.md`.
