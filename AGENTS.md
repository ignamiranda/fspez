## Commands
- `flutter analyze` — lint + static analysis (all errors)
- `flutter test` — unit tests only (no widget/integration tests yet)
- `flutter run` — runs on Windows desktop (default target)
- `flutter build windows` — Windows release build

## Architecture
- **`lib/src/data/`** — `RedditClient` (HTTP wrapper with `ApiEndpoint` enum for header config), `AuthAcquirer` (CDP cookie extraction + polling + modhash + username), repositories (feed, comment, vote, save, subreddit, user, inbox), notifiers (`FeedPageNotifier`, `HideNotifier`, `OptimisticStateNotifier` base + `VoteNotifier`, `SaveNotifier`, `ActiveAccountNotifier`), parsers (feed, comment, inbox, shared), domain-specific provider files (`auth_providers.dart`, `feed_providers.dart`, `comment_providers.dart`, `inbox_providers.dart`, `user_providers.dart`, `write_providers.dart`, `reddit_client_provider.dart`)
- **`lib/src/domain/`** — models (`Post`, `Comment`, `Feed`, `Account`, `SessionCookie`, `Subreddit`, `Message`, `MessageFeed`, `UserProfile`, `UserComment`), enums (`FeedSort`, `VoteDirection`, `PostType`, `FeedKind`, `InboxTab`, `FeedPageKind`). Pure data objects, no logic.
- **`lib/src/presentation/`** — `app.dart` (MaterialApp + bottom nav), screens (feed, inbox, account, login, auth_webview, post_detail, saved, hidden, search, subreddit_feed, user_profile, submit, compose), widgets (`PostCard`, `PostHeader`, `PostActions`, `PostList`, `CommentTree`), utils (`format_utils.dart`, `interaction_helpers.dart`)
- **Entrypoint**: `lib/main.dart` — initializes `SharedPreferences`, overrides into `ProviderScope`, launches `FspezApp`
- **Riverpod**: `StateNotifierProvider.family<FeedPageNotifier, FeedPageState, FeedPageConfig>` for paginated feeds, `StateNotifierProvider` for vote/save/hide/active-account, `FutureProvider.family` for post detail and subreddit info.
- **StateNotifier pattern**: `VoteNotifier` / `SaveNotifier` extend `OptimisticStateNotifier<String, V>` which provides `optimisticSet()` / `optimisticRevert()` / `effective()`. Both use optimistic updates; SaveNotifier reverts on any error and rethrows, VoteNotifier keeps optimistic state on error (swallows it). `HideNotifier` is a plain `StateNotifier<Set<String>>` (no revert needed — hide is one-way).
- **Auth**: No OAuth. `AuthAcquirer` (single module) handles: CDP `Network.getCookies` polling up to 10 attempts at 500ms, modhash fetch via `GET /api/me`, username extraction (JS eval → API call → cookie heuristic). Screen only calls `acquirer.acquire(controller)` + `acquirer.extractUsername(cookie)`.
- **Pagination**: `FeedPageNotifier` (StateNotifier) owns cursor/after, loading flags, and fetch dispatch. Screens own their `ScrollController` with near-bottom listener calling `notifier.loadMore()`. `FeedPageConfig` (kind + sort + identifier) keys the `feedPageProvider.family`. Kinds: `home`, `popular`, `popularAll`, `saved`, `hidden`, `search`, `subreddit`, `user`.

## Write operations
| Operation | Endpoint | Client method | Modhash? | Domain |
|-----------|----------|---------------|----------|--------|
| Vote | `POST /api/vote` | `postForm()` | No | www |
| Save | `POST /api/save` | `save()` | Yes | old |
| Unsave | `POST /api/unsave` | `unsave()` | Yes | old |
| Delete | `POST /api/del` | `postForm()` | No | www |
| Hide | `POST /api/hide` | `postForm()` | No | www |
| Unhide | `POST /api/unhide` | `postForm()` | No | www |
| Comment | `POST /api/comment` | `comment()` | Yes | www |
| Compose PM | `POST /api/compose` | `compose()` | Yes | www |
| Submit post | `POST /api/submit` | `submit()` | Yes | old |

## Save/Delete note
- Save/unsave goes through `RedditClient.save()`/`RedditClient.unsave()` which hit `https://old.reddit.com/api/save` with browser-headers. Requirements:
  - Domain: `old.reddit.com` (NOT `www.reddit.com`)
  - Cookie: full `rawCookie` string (CDP all-cookies join), not just `reddit_session`
  - `X-Modhash` header (NOT in Cookie) — extracted via `GET /api/me → data.modhash`
  - `X-Requested-With: XMLHttpRequest`, `Accept: */*`, `Content-Type: application/x-www-form-urlencoded; charset=UTF-8`
- Delete (`/api/del`) works with `postForm` — no modhash, no old.reddit.com.
- Hide (`/api/hide`, `/api/unhide`) works with `postForm` — no modhash, no old.reddit.com.
- Vote (`/api/vote`) works with just `reddit_session` + form-encoded content type (no modhash, no old.reddit.com).

## Delete UX
- Delete button shows only for own posts (`post.author == currentUsername`). Checked in `PostList` via `currentUsername` prop.
- Delete shows confirmation dialog before calling API.
- Comment delete also supported via `CommentTree.onDelete` callback.

## Hide UX
- Hide button (`Icons.visibility_off_outlined`) shown on all posts.
- Optimistic: post removed from `visiblePosts` immediately.
- On API failure, post reappears (reverted from `HideNotifier`'s set).
- Hidden posts viewable at Account → Hidden (`HiddenScreen` → `/user/{user}/hidden`).

## PostDetailScreen: API-fetched post
`PostDetailScreen` uses the API-fetched `Post` from `postDetailProvider` for the header (falling back to `widget.post` while loading). This ensures correct author display when navigating from user profile comments (where `_buildMinimalPost` creates a fake `Post` with the commenter's username).

## Feed sort: path-based vs query-param
Reddit API ignores `?sort=` query parameter on aggregate feeds (`/r/popular`, `/r/all`, `/r/popular/hot`). Sort must be in the path: `/r/popular/hot.json`, `/r/popular/new.json` etc. The `fetchPopularAll()` method uses `_popularPathForSort()` to build the correct path.

## Open link in browser
Non-self posts show `Icons.open_in_new` button in `PostActions`. Uses `InAppBrowser` from `flutter_inappwebview` (existing dependency). Post detail screen also shows tappable link URL for `PostType.link` posts.

## Debugging Reddit API 403s
Use `controller.callDevToolsProtocolMethod('Runtime.evaluate', {awaitPromise: true, returnByValue: true, expression: '...'})` to make a same-origin `fetch()` from within the WebView. Override `XMLHttpRequest.prototype.setRequestHeader` to capture exact browser request headers.

## Key files
| File | Purpose |
|------|---------|
| `lib/src/data/reddit_client.dart` | HTTP wrapper — get, post, postForm, save/unsave, delete, hide/unhide, submit, comment, compose |
| `lib/src/data/reddit_client_provider.dart` | Singleton `RedditClient` provider |
| `lib/src/data/feed_providers.dart` | `feedRepositoryProvider` + `feedPageProvider.family` |
| `lib/src/data/feed_pagination.dart` | `FeedPageNotifier` + `FeedPageConfig` + `FeedPageState` + `FeedPageKind` + `fetchForConfig()` |
| `lib/src/data/feed_repository.dart` | Feed fetching (home, popular, popularAll, subreddit, search, user, saved, hidden) |
| `lib/src/data/vote_notifier.dart` | Optimistic vote toggle, swallows errors |
| `lib/src/data/save_notifier.dart` | Optimistic save toggle, reverts + rethrows on error |
| `lib/src/data/hide_notifier.dart` | `StateNotifier<Set<String>>` for hidden fullnames, reverts on error |
| `lib/src/data/write_operation_notifier.dart` | Base class `WriteOperationNotifier<V>` for vote/save |
| `lib/src/data/auth_acquirer.dart` | CDP cookie acquisition + modhash + username extraction |
| `lib/src/data/modhash_fetcher.dart` | Extracts modhash from `/api/me` |
| `lib/src/data/username_extractor.dart` | 3 username strategies (JS eval, API call, cookie heuristic) |
| `lib/src/data/account_notifier.dart` | `ActiveAccountNotifier` — multi-account state |
| `lib/src/data/auth_providers.dart` | `activeAccountProvider`, `accountsProvider`, `accountRepositoryProvider` |
| `lib/src/data/comment_providers.dart` | `commentRepositoryProvider`, `postDetailProvider.family`, `subredditInfoProvider` |
| `lib/src/data/inbox_providers.dart` | Inbox pagination |
| `lib/src/data/user_providers.dart` | `userRepositoryProvider`, `userProfileProvider.family` |
| `lib/src/data/write_providers.dart` | `voteProvider`, `saveProvider`, `hideProvider` |
| `lib/src/data/feed_parser.dart` | `FeedParser` — parses feed JSON into `Feed` + `Post` |
| `lib/src/data/comment_parser.dart` | `CommentParser` — parses comment trees |
| `lib/src/data/optimistic_state_notifier.dart` | Base class for optimistic-update `StateNotifier` |
| `lib/src/presentation/screens/auth_webview_screen.dart` | WebView login flow, delegates to `AuthAcquirer` |
| `lib/src/presentation/screens/feed_screen.dart` | Main feed — home/popular/popularAll with sort toggle |
| `lib/src/presentation/screens/post_detail_screen.dart` | Post + comments, vote/save/delete/reply |
| `lib/src/presentation/screens/account_screen.dart` | Account list, My Profile, Saved, Hidden, History, Log Out |
| `lib/src/presentation/screens/saved_screen.dart` | Saved posts feed |
| `lib/src/presentation/screens/hidden_screen.dart` | Hidden posts feed |
| `lib/src/presentation/screens/search_screen.dart` | Search with infinite scroll |
| `lib/src/presentation/screens/user_profile_screen.dart` | Profile with Posts/Comments/About tabs |
| `lib/src/presentation/screens/subreddit_feed_screen.dart` | Subreddit feed with header + subscribe |
| `lib/src/presentation/screens/submit_screen.dart` | Text/link post submission |
| `lib/src/presentation/screens/compose_screen.dart` | HTTP compose PM |
| `lib/src/presentation/widgets/post_list.dart` | Shared `PostList` for PostCard lists with hidden filtering |
| `lib/src/presentation/widgets/post_actions.dart` | `PostHeader` + `PostActions` — vote/save/open/delete/hide |
| `lib/src/presentation/widgets/comment_tree.dart` | Collapsible threaded comments with vote/save/reply/delete |
| `lib/src/presentation/utils/interaction_helpers.dart` | `handleVote()`/`handleSave()`/`handleDelete()` |
| `lib/src/presentation/utils/format_utils.dart` | `formatCount()`/`timeAgo()` |
| `docs/adr/0001-cookie-only-auth.md` | Why no OAuth (API pricing changes) |
| `.opencode/skills/reddit-api-auth/SKILL.md` | Debugging modhash-based auth 403s |
| `.opencode/skills/learn/SKILL.md` | Extract reusable knowledge into skills |
| `opencode.json` | Custom `/learn` command |

## Constraints
- No OAuth, no Reddit app registration — all auth via session cookies
- Save endpoints need modhash + old.reddit.com; vote/delete/hide don't
- SDK `^3.4.0`, Flutter `^3.22.0`, `flutter_inappwebview` for WebView, `shared_preferences` for persistence
- No `build_runner` / code generation output in repo (freezed/json_serializable listed but not run)
- Feed sort on aggregate feeds (`/r/popular`) must be path-based, not query-param
