# fspez

A cookie-based Flutter Reddit client that avoids OAuth to decouple the app's existence from Reddit's API pricing.

## Language

**User**:
The physical human holding the device.
_Avoid_: Person, client

**Account**:
A single Reddit identity (username, cookie session, preferences). A User may own multiple Accounts and switch between them.
_Avoid_: User (when referring to a Reddit identity)

**InboxItem**:
A single item in the inbox listing. Reddit's inbox mixes private messages and comment replies or mentions in the same feed. An InboxItem is either a DirectMessage or a CommentNotification — never both.
_Avoid_: Message (when referring to the union), Thing

**Inbox**:
The inbox listing surface in the app. Groups InboxItems into tabs (All, Unread, Sent). Supports pagination and mark-as-read.
_Avoid_: Messages, MessageFeed

**OverviewItem**:
A single item in a user's overview or saved listing. Reddit's overview mixes posts and comments authored by the same Account. An OverviewItem is either a Post or a Comment — never both.
_Avoid_: Thing, UserContent

**Feed**:
Any paginated list of post previews rendered as cards. The source (home, popular, subreddit, search results) is a parameter on the Feed, not a different type.
_Avoid_: Listing, stream

**Subreddit**:
A topic-based community on Reddit (called "subreddit" in API/URLs, "community" in Reddit UI). Referred to as Subreddit in code and API schemas; UI text may use "community" for display.
_Avoid_: Community (in code or API contexts)

**Draft**:
A locally saved, unsubmitted post, comment, or direct message. Stored on-device, not on Reddit's servers, until the User chooses to submit or discard it.
_Avoid_: Temp, work-in-progress

**Guest**:
A mode where the User browses Reddit without an Account. No session cookie, no modhash. Read operations (feed, post, comments, search) work normally. Write operations (vote, comment, submit, inbox) prompt login via confirmation dialog → AuthWebViewScreen. Guest mode is ephemeral — not persisted across app restarts.
_Avoid_: Anonymous, offline

**PostBody**:
The canonical layout block for a single post, rendered identically in feed cards and detail headers. Consists of metadata row (subreddit, author, timestamp, awards), title, media block (images, video, gallery if present), and action bar (vote, comment, save, share). In feed, PostBody *is* the card; in detail, it is the header — additional content (full selftext, comments) is appended below but does not alter the PostBody layout.
_Avoid_: PostHeader (implies a different layout than feed), PostCard (refers to the feed wrapper, not the layout)

**Comment**:
A reply to a post or another comment in a thread. Comments are organized in a tree structure via `depth` and `replies`. Each Comment can be individually collapsed or expanded by the User.
_Avoid_: Reply (ambiguous — also means the action of replying), Thread
