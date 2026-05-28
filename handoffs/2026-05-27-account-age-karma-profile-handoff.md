# Account age & karma breakdown on profiles

## Scope
Show "Redditor for X years" and post vs comment karma split on `UserProfileScreen`, matching official Reddit mobile profile layout.

## What to build
- Parse `created_utc` from `/user/{username}/about.json` → compute account age (years/months)
- Display "Redditor for X years" or "X yr. ago" text on the profile header
- Parse `link_karma` (post karma) and `comment_karma` from the same endpoint → display as "Post karma: X  Comment karma: X" or stacked layout
- Handle `trophy`/`awarder_karma`/`awardee_karma` fields as available (nice-to-have)
- The data likely already flows through existing `UserProfileScreen` — inspect `user_profile_screen.dart` and the profile data models/API responses

## Where to inspect
- `lib/src/presentation/screens/user_profile_screen.dart` — profile header rendering
- `lib/src/domain/models/user.dart` or profile model — confirm `created_utc`, `link_karma`, `comment_karma` are parsed
- `lib/src/data/api_responses.dart` — profile JSON field mapping

## Design notes
- Format account age: "Redditor for 3 years" (full years preferred, "6 months" if <1yr, "X days" if <1mo)
- Karma display: clean numeric (no "k" abbreviation needed but optional) showing post vs comment split
- Place below username, above bio/description section
- Account age is computed locally from `created_utc` timestamp — no extra API call

## Non-goals
- Trophy/achievement case display (future)
- Awarder/awardee karma display (nice-to-have)
- Karma history graph or trends

## Manual test steps
1. `flutter run`
2. Tap any username → UserProfileScreen
3. Verify "Redditor for X years" or similar age text appears
4. Verify post karma and comment karma shown separately
5. Check a brand-new account ("Redditor for 0 days") — verify graceful display
6. Check own profile vs other users — should work identically
