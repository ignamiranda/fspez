# User flair display in posts and comments

## Problem

Reddit shows community-specific user flair (text, background color, emoji/image) next to usernames in posts and comments. fspez parses the API responses but does not render user flair, making posts and comments feel less authentic to Reddit's identity.

## Scope

**User flair rendering:**
- Parse and display `author_flair_text` and related fields (`author_flair_richtext`, `author_flair_background_color`, `author_flair_text_color`) from post and comment API responses
- Render a small styled chip/badge next to the author name in:
  - **Post cards** (`PostCard` in feed, search, subreddit, saved/hidden/history)
  - **Post detail header** (author row in `PostDetailScreen`)
  - **Comment tree** (author row in `CommentTree`)
  - **Inbox messages** (author row in `InboxScreen`)
- The chip should show:
  - Flair text with appropriate background/text color (from API-provided color fields)
  - Emoji in text (already rendered by standard Flutter text widget)
  - Rendered richtext parts (from `author_flair_richtext` array) if available — fall back to plain `author_flair_text`

**Styling:**
- Small rounded chip/pill, ~16-18px height, with horizontal padding
- Font size slightly smaller than username, weight normal or medium
- Background/text color from API fields (fall back to default gray chip with dark text if not specified)
- Left margin from the username, not a clickable target (no navigation on tap)
- Overflow: truncate long flair text with ellipsis, max ~120px

**Data layer:**
- Investigate whether `author_flair_text`, `author_flair_richtext`, `author_flair_background_color`, `author_flair_text_color` are already parsed in `api_responses.dart` domain models for `Post` and `Comment`
- If fields exist but unused, add rendering only
- If fields are missing from domain models, add them (they're present in the Reddit API JSON)

## Out of scope

- Selecting/editing user flair in a subreddit (requires subreddit-specific API, complex permission model)
- Post flair display in the feed (covered by `post-flair-selection` if that includes display, but they're distinct)
- Clickable flair interactions (no menu on tap)
- Flair image sprites or CSS classes (modern Reddit uses richtext/emoji, not CSS sprites)

## Implementation notes

- Examine `lib/src/data/api_responses.dart` for existing flair fields in `ApiPost`, `ApiComment`
- Examine domain models (`lib/src/domain/models/`) for `Post`, `Comment` to see if flair fields are mapped
- If parsing already exists, this is purely a presentation change in `PostCard`, `PostDetailScreen`, `CommentTree`, and `InboxScreen`
- If not, add parsing in `api_responses.dart` and the domain mapping layer
- Consider extracting a reusable `UserFlairChip` widget for consistency
- Test: feed with posts from flair-using subreddits should show colored flair chips next to author names
