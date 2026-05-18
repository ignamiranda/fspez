# fspez

A mobile Reddit client for iOS and Android that supports multiple accounts without relying on the paid Reddit API. Authentication uses session cookies extracted from an in-app WebView login rather than OAuth.

## Language

**Account**:
A Reddit user identity managed within fspez, represented by a session cookie.
_Avoid_: Profile, user (ambiguous with Reddit's `User` concept — see Flagged ambiguities)

**Session Cookie**:
A `reddit_session` cookie extracted from a WebView login session. Used to authenticate all requests to Reddit's internal API.
_Avoid_: Token, OAuth token, API key

**Feed**:
A paginated, sortable stream of posts. Includes Home (subscriptions), Popular, All, and user-created Multireddits.
_Avoid_: Timeline, stream, frontpage

**Post**:
A Reddit submission: link, self-post, image, gallery, video, crosspost, or poll.
_Avoid_: Submission, article, thread

**Subreddit**:
A Reddit community. Has its own feed, rules, moderators, and subscribers.
_Avoid_: Community, sub, board

**Multireddit**:
A user-created feed that combines posts from multiple Subreddits into a single Feed.
_Avoid_: Multi, custom feed, collection

**Comment**:
A reply on a Post, forming a threaded tree. Can be voted on, saved, and reported.
_Avoid_: Reply (ambiguous with Inbox replies)

**Inbox**:
The collection of private messages, comment replies, post replies, and username mentions for an Account.
_Avoid_: Notifications (too broad), messages (only one part of Inbox)

**Chat**:
Reddit's real-time messaging system. Distinct from Inbox messages.
_Avoid_: Messages, DMs

**Modmail**:
The moderator-to-user messaging system, separate from both Chat and Inbox.
_Avoid_: Mod messages, mod inbox

**Mod Queue**:
A list of reported Posts and Comments within a moderated Subreddit, awaiting moderator action (approve/remove).
_Avoid_: Reports list, flagged items

**Save**:
A bookmark on a Post or Comment, tied to an Account. Accessible from the Account's profile.
_Avoid_: Bookmark, favorite

**NSFW**:
Content flagged by Reddit as not suitable for work. Filtering can mirror the Account's Reddit preference or be overridden locally.
_Avoid_: Mature content, 18+

## Relationships

- A **Feed** contains many **Posts**
- A **Post** belongs to one **Subreddit** and contains many **Comments**
- An **Account** can vote on many **Posts** and **Comments**, save many **Posts** and **Comments**, and moderate many **Subreddits**
- An **Account** has one **Inbox** and participates in many **Chats**
- A **Multireddit** combines multiple **Subreddits**
- A **Mod Queue** belongs to one **Subreddit** and contains many **Posts** and **Comments**
- **Modmail** connects a **Subreddit**'s moderators with an external **Account**

## Example dialogue

> **Dev:** "When an Account receives a comment reply, does it appear in their Inbox or as a Chat message?"
> **Domain expert:** "Inbox. Chat is a separate real-time system. Inbox is for notifications and private messages — Chat is for ongoing conversations."
>
> **Dev:** "What happens to cached Posts in a Feed when the user switches Accounts?"
> **Domain expert:** "The Feed refreshes to show the new Account's subscriptions. The old Account's Feed state is discarded — we don't preserve scroll position across Account switches."
>
> **Dev:** "Can a user moderate a Subreddit from one Account while browsing with a different Account?"
> **Domain expert:** "Only the active Account's moderation permissions apply. The user must switch to the Account that's listed as a moderator of that Subreddit."

## Learned architecture

### Modhash authentication
Reddit's old-style API endpoints (`/api/save`, `/api/unsave`, etc.) require an `X-Modhash` header alongside the session cookie. The modhash is a per-session CSRF token embedded in every page response.

**Where to get it:** `GET /api/me` returns `data.modhash` in its JSON response.
**Where it's stored:** `SessionCookie.modhash`, extracted during the WebView login flow (`_fetchModhash` in `auth_webview_screen.dart`).

**Critical details:**
- The modhash is NOT a cookie — it's sent as `X-Modhash` header.
- Different Reddit subdomains accept the same modhash.
- For old Reddit endpoints (`old.reddit.com`), also send `X-Requested-With: XMLHttpRequest` and `Accept: */*`.
- `www.reddit.com`'s `/api/save` returns 403; use `old.reddit.com` instead.
- Send the full `rawCookie` string (all cookies via `; ` join), not just `reddit_session`.
- `Content-Type` must include `charset=UTF-8` suffix.
- Vote (`/api/vote`) works with just `reddit_session` and no modhash — save is stricter.

### Debugging Reddit API 403s
When a Reddit endpoint returns 403 for cookie-authenticated requests:
1. Use the existing CDP infrastructure (`callDevToolsProtocolMethod`) with `Runtime.evaluate` + `awaitPromise` + `returnByValue` to make a same-origin `fetch()` call from within the WebView. This eliminates TLS fingerprint / HTTP stack differences.
2. Override `XMLHttpRequest.prototype.open/send` and `XMLHttpRequest.prototype.setRequestHeader` to capture the exact request headers the browser's XHR sends.
3. Compare against what the Dart `http` package sends. Key differences found this way: `X-Modhash`, `X-Requested-With`, `Accept`, full cookie string, `old.reddit.com` vs `www.reddit.com`.

## Flagged ambiguities

- "User" was used to mean both a Reddit user (someone else's profile you're viewing) and an Account (your own logged-in identity). Resolved: **Account** for your own identity, **Reddit user** for others. The profile view shows a Reddit user; the settings view manages Accounts.
