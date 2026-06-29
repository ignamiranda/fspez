# fspez

A mobile Reddit client that supports multiple accounts without the paid Reddit API — cookie-based auth, no OAuth required.

Uses a WebView login flow to obtain a Reddit session cookie, then communicates with Reddit's old and new API endpoints directly. No API key, no OAuth app registration needed.

## Features

- **Cookie-based login** via WebView (no Reddit API token or app registration)
- **Feeds**: Home, Popular, subreddit feeds with hot/new/top/rising/controversial sorting
- **Vote, save, hide, delete** posts and comments with optimistic UI updates
- **Media viewer** with gesture-first image/gallery browsing (pinch zoom, double-tap, swipe)
- **Post submission**: text, link, image, gallery, and video posts
- **Collapsible threaded comments** with vote/save/reply/delete
- **User profiles** with Posts / Comments / About tabs
- **Multi-account** support with account switcher
- **Inbox** with All / Unread / Sent tabs, expandable message threads, inline replies
- **Search** with infinite scroll across posts, users, and subreddits
- **Dark mode** (system / light / dark / AMOLED)
- **Settings**: theme picker, feed density, comment sort, blur toggles, award visibility, media prefetch
- **Post flair** selection with caching and debounced fetching
- **Offline cache** with stale-while-revalidate for feeds
- **Report content** with per-subreddit rules
- **Block users** and mute communities

## Architecture

Cookie-based API calls avoid Reddit's OAuth pricing. Session cookies are stored encrypted via `flutter_secure_storage`. The app uses Riverpod for state management and follows a data/domain/presentation layer split.

| Layer | Location | Purpose |
|-------|----------|---------|
| Data | `lib/src/data/` | API client, parsers, notifiers, repositories |
| Domain | `lib/src/domain/` | Models, enums |
| Presentation | `lib/src/presentation/` | Screens, widgets, theme, utils |

## Getting Started

```sh
flutter pub get
flutter run          # runs on connected device/emulator
flutter test
flutter analyze
```

Requires Flutter 3.22+ and Dart 3.4+.

Targets: Android, Windows (experimental), Web (limited).

## License

MIT
