## Save feature: Modhash requirement

`/api/save` and `/api/unsave` require ALL of these (any missing = 403):
- Domain: `old.reddit.com` (NOT `www.reddit.com`)
- Cookie header: full `rawCookie` string (all cookies via `; ` join from CDP), not just `reddit_session`
- `X-Modhash` header — a per-session CSRF token
- `X-Requested-With: XMLHttpRequest`
- `Accept: */*`
- `Content-Type: application/x-www-form-urlencoded; charset=UTF-8`

### Where to get modhash
`GET /api/me` returns `data.modhash`. Extracted during WebView login flow via `_fetchModhash()` in `auth_webview_screen.dart`. Stored on `SessionCookie.modhash` and persisted in `AccountRepository`.

### Note
`/api/vote` works with just `reddit_session` cookie + `Content-Type: application/x-www-form-urlencoded` (no modhash, no old.reddit.com requirement). Vote is less strict than save.

## Debugging Reddit API 403s

When a cookie-authenticated endpoint returns 403 and a browser can do it:

1. **CDP Runtime.evaluate**: Use `callDevToolsProtocolMethod('Runtime.evaluate', {awaitPromise: true, returnByValue: true, expression: '...'})` to make a same-origin `fetch()` from within the WebView. This eliminates TLS fingerprint / HTTP stack differences.

2. **Capture browser XHR headers**: Override `XMLHttpRequest.prototype.open/send/setRequestHeader` and `window.fetch` to intercept the real save request when clicking the button on `old.reddit.com`.

3. **Compare headers**: Log what the browser sends vs what Dart's `http` package sends. Key differences found this way: `X-Modhash`, `X-Requested-With`, `Accept`, full cookie string, `old.reddit.com` vs `www.reddit.com`.
