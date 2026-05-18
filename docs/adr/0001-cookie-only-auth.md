# Cookie-only authentication

fspez authenticates all Reddit requests using a `reddit_session` cookie extracted from an in-app WebView login session. OAuth is not used at any point.

This avoids registering a Reddit developer application (`client_id`) entirely. Without a `client_id`, there is no centralized credential for Reddit to throttle or revoke. Each user's session is independent — the app cannot be killed by API pricing changes or a single application ban the way Apollo, BaconReader, and other OAuth-based clients were.

**Considered Options**: OAuth-based authentication was the obvious initial path. OAuth would be cleaner — official endpoints, documented rate limits, no cookie lifecycle management. But OAuth binds every user's token to a single `client_id`. When Reddit introduced API pricing in July 2023, it rendered the OAuth free tier commercially non-viable for third-party clients. A cookie-only approach removes Reddit's leverage over the app's existence.

**Consequences**: Cookie extraction requires a WebView login flow rather than the system browser. This is less ideal for user trust (they can't verify the SSL certificate) and app store review. Cookies expire and must be refreshed silently. Reddit's internal API has no documented rate limits or stability guarantees — the app depends on undocumented, uncommitted endpoints.
