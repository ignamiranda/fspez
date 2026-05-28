# Muted communities management

## Scope
Add a screen to view and manage muted subreddits, including unmute functionality, accessible from Account/Settings. Completes the community-mute feature.

## What to build
- Create a "Muted communities" entry in Account screen or Settings screen
- Fetch muted subreddits list via Reddit API — verify endpoint: likely `/api/v1/me/muted` or part of `/subreddits/mine/subscriber` with a `?where=muted` or look for a dedicated mutelist endpoint
- Display muted subreddits: subreddit name, icon (if available), muted date (if available)
- Unmute action: tap → confirm dialog → call unmute API
- Empty state: "No muted communities"
- Handle pagination if needed

## Where to inspect
- `lib/src/presentation/screens/account_screen.dart` — entry point
- `lib/src/data/reddit_client.dart` — verify mute/unmute API methods from community-mute-unmute handoff
- `lib/src/data/subreddit_repository.dart` — existing subreddit data methods
- Existing mute API: `POST /api/mute/mute_subreddit` with subreddit name — verify from community-mute-unmute handoff
- Unmute API: similar with unmute endpoint

## Implementation notes
- Muted subreddits list endpoint is the biggest unknown — verify during community-mute-unmute implementation
- Fallback: if API list endpoint doesn't exist, store muted list locally in SharedPreferences
- Each entry shows: subreddit name with icon (if available), "Unmute" button
- Unmute: confirm dialog "Unmute r/subreddit? You will see posts from this community in your feed again."
- After unmute, remove from list and optionally navigate to subreddit
- Refresh list after each unmute
- Handle subreddits that were deleted or made private

## Dependencies
- community-mute-unmute handoff (confirms working mute/unmute API)

## Non-goals
- Muting from this screen (muting is done from subreddit pages/posts — this is management only)
- Bulk unmute
- Per-mute reason or duration

## Manual test steps
1. `flutter run`
2. Have at least one muted subreddit
3. Navigate to Account → Muted communities
4. Verify muted subreddit appears with name
5. Tap unmute → confirm dialog → verify removed from list
6. Verify that subreddit's posts now appear in feed/Popular/All
7. Test with no muted subreddits — verify empty state
