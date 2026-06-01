# Handoff: Moderator list display

## Approved feature

Implement **moderator list display** for subreddit/community pages.

## Current goal

Implement features to reach feature parity with the official Reddit mobile app.

## Why this feature

Official Reddit exposes a community moderator list from subreddit/community info surfaces. Existing inventory confirmed subreddit browsing and subscribe/unsubscribe, with approved handoffs for rules/about/wiki, but no surfaced moderator list flow was identified.

## Existing related implementation

Inspect these areas first:

- `lib/src/presentation/screens/subreddit_feed_screen.dart`
  - Existing subreddit page/header. Likely entry point for a Moderators action, possibly alongside About/Rules/Wiki.
- `lib/src/presentation/screens/user_profile_screen.dart`
  - Existing profile screen; moderator names should link here.
- `lib/src/data/reddit_client.dart`
  - Existing authenticated GET patterns and subreddit API helpers.
- `lib/src/domain/models/`
  - Add moderator/community moderator model if none exists.
- `lib/src/data/api_responses.dart`
  - Add manual parsing for moderator listing responses if consistent with existing style.

Already implemented features to avoid re-suggesting as new work:

- Feed browsing/sorting/refresh/pagination.
- Search across posts/communities/comments/media/profiles.
- Subreddit browsing and subscribe/unsubscribe.
- User profiles.
- Inbox/messages and compose.
- Text/link post submit.
- Saved/hidden/history screens.
- Multi-account auth/session switching.
- Fullscreen media/gallery/video viewing.
- Basic comment collapse/expand.
- Post/comment body editing, with a separate handoff for remaining edit gaps.

Related approved handoffs that may interact with this work:

- `handoffs/2026-05-27-subreddit-rules-display-handoff.md`
- `handoffs/2026-05-27-subreddit-sidebar-about-details-handoff.md`
- `handoffs/2026-05-27-subreddit-wiki-pages-handoff.md`

## Suggested implementation scope

Smallest useful vertical slice:

1. Add a Moderators entry point from `SubredditFeedScreen` or the future About area.
2. Fetch subreddit moderators.
3. Display moderator usernames in a list.
4. Let users open a moderator's `UserProfileScreen`.
5. Show mod role/permissions only if available and easy to parse.
6. Handle hidden/private/unavailable moderator lists gracefully.

## Technical discovery needed

Before editing, inspect:

- Current subreddit screen navigation/action patterns.
- Current route/navigation pattern for opening user profiles.
- `RedditClient.get()` behavior for listing endpoints and `.json` suffixes.
- Reddit moderator endpoint and response shape, likely `/r/{subreddit}/about/moderators.json` or equivalent.

Verify endpoint behavior before implementation. Some communities may hide moderator details or return limited data.

## UX requirements

- Moderator list should be discoverable from community context, not global navigation.
- Usernames should be tappable and navigate to existing profile view.
- Empty/hidden/error states should be friendly and specific.
- Avoid presenting permissions/roles if the API data is unclear or noisy.

## Deferred out of scope

- Moderator tools/actions.
- Modmail.
- Editing moderator lists/permissions.
- Full community About consolidation; separate handoffs cover About/Rules/Wiki.

## Validation

Run after implementation:

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test` if tests are added/changed.
- Manual `flutter run` check on a subreddit with visible moderators and one unavailable/private case if practical.

## Suggested agents

- Reuse explorer session `exp-2 Check post edit implementation` for subreddit screen/client context if more discovery is needed.
- Use `@fixer` for bounded implementation after endpoint/model/UI targets are confirmed.
- Use `@designer` only if consolidating Moderator/Rules/About/Wiki into a polished community info UI.
- Use `@oracle` only if deciding shared architecture for community info surfaces becomes ambiguous.
