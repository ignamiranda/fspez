---
name: reddit-api-auth
description: Use when debugging Reddit API 403 errors with cookie-based auth, or when implementing write operations (save, unsave, submit) against Reddit's old-style API endpoints.
---

# Reddit API Cookie-Based Auth

## Save/Unsave requirements

Save/unsave is handled by `RedditClient.save()` / `RedditClient.unsave()` in `lib/src/data/reddit_client.dart`. Callers use `SaveRepository` which delegates to `RedditClient` — they don't construct old.reddit.com requests or headers manually.

`/api/save` and `/api/unsave` require ALL of these (any missing = 403):

| Requirement | Detail |
|-------------|--------|
| **Domain** | `https://old.reddit.com/api/save` (NOT `www.reddit.com`) |
| **Cookie** | Full `rawCookie` string — all cookies joined with `; ` from CDP `Network.getCookies` |
| **X-Modhash** | Per-session CSRF token from `GET /api/me` → `data.modhash` |
| **X-Requested-With** | `XMLHttpRequest` |
| **Accept** | `*/*` |
| **Content-Type** | `application/x-www-form-urlencoded; charset=UTF-8` |

## Modhash lifecycle

### Extraction
Call `GET /api/me` with the `reddit_session` cookie. Response JSON:
```json
{ "data": { "modhash": "rti2ztvvgd3...", "name": "username" } }
```

### Storage
Store on `SessionCookie.modhash` during the WebView login flow. Persist with `AccountRepository` alongside `rawCookie`.

### Usage
Send as `X-Modhash` header on every write request that needs it. It does NOT go in the Cookie header.

## Search endpoint

Reddit search is `GET https://www.reddit.com/search?q=<query>` (NOT `/api/search`). Returns standard listing format — compatible with `FeedParser.parseFeed`. The `.json` suffix is appended automatically by `RedditClient.get()`.

## Submit (post creation)

`/api/submit` requires old.reddit.com + full browser headers + modhash (same as save/unsave):

- **Domain**: `https://old.reddit.com/api/submit`
- **Headers**: Same as save (User-Agent: Mozilla, X-Modhash, X-Requested-With, full Cookie, Content-Type with charset)
- **Body**: `kind=self|link&sr=<subreddit>&title=<title>&text=<text>&url=<url>&uh=<modhash>`

Use `RedditClient.submit()` in `lib/src/data/reddit_client.dart`.

## Comment (posting replies)

`/api/comment` is simpler — uses `www.reddit.com` NOT old.reddit.com, and lighter headers:

- **Domain**: `https://www.reddit.com/api/comment`
- **Headers**: `User-Agent: fspez/0.1.0`, `Content-Type: application/x-www-form-urlencoded`, `Cookie: reddit_session=...`, `X-Modhash` (still needed)
- **Body**: `thing_id=t3_xxx|t1_xxx&text=<comment>&uh=<modhash>`

Use `RedditClient.comment()` in `lib/src/data/reddit_client.dart`.

## Vote vs Save

`/api/vote` is less strict — works with just:
- `Cookie: reddit_session=<value>`
- `Content-Type: application/x-www-form-urlencoded`

No modhash, no old.reddit.com requirement.

## Debugging 403s

When a cookie-authenticated Reddit endpoint returns 403 but works in a browser:

### 1. CDP Runtime.evaluate (eliminates HTTP stack differences)
Use `InAppWebViewController.callDevToolsProtocolMethod`:
```dart
await controller.callDevToolsProtocolMethod(
  methodName: 'Runtime.evaluate',
  parameters: {
    'awaitPromise': true,
    'returnByValue': true,
    'expression': '''
(async function() {
  const r = await fetch('/api/save', {
    method: 'POST',
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: 'id=t3_xxx',
    credentials: 'include'
  });
  return { status: r.status, body: await r.text() };
})()
''',
  },
);
```

### 2. Capture browser XHR headers
Override XHR methods before clicking the save button to see what the browser actually sends:

```javascript
var origSetHeader = XMLHttpRequest.prototype.setRequestHeader;
XMLHttpRequest.prototype.setRequestHeader = function(h, v) {
  if (!this._reqHeaders) this._reqHeaders = {};
  this._reqHeaders[h] = v;
  return origSetHeader.apply(this, arguments);
};
```

### 3. Key differences found via this technique
- `X-Modhash` header (missing from Dart requests)
- Full cookie string vs just `reddit_session`
- `old.reddit.com` domain vs `www.reddit.com`
- `X-Requested-With: XMLHttpRequest`
- `Content-Type` with `charset=UTF-8` suffix
