# Dark mode / theme support

## Scope
Add Light, Dark, and AMOLED Dark themes to the app with a persisted toggle, matching official Reddit mobile theme support.

## What to build
- Define three `ThemeData` objects: `lightTheme`, `darkTheme`, `amoledDarkTheme` (AMOLED = pure black `Color(0xFF000000)` backgrounds)
- Create a persistent setting via `SharedPreferences` — key `theme_mode` with values `light` / `dark` / `amoled` / `system` (system follows platform)
- Wire theme state via Riverpod (`StateNotifierProvider` for theme mode)
- In `FspezApp` (or `MaterialApp`), consume the provider and pass selected theme to `ThemeData` / `darkTheme`
- Add theme toggle to the in-app settings screen (handoff #1)
- Ensure all existing widgets respect the theme (check for hardcoded colors or light-only values)
- Respect `MediaQuery.platformBrightness` for "System default" option

## Where to inspect
- `lib/src/presentation/app.dart` or `lib/main.dart` — look for `MaterialApp` / theme setup
- `lib/src/presentation/screens/account_screen.dart` — potential early entry for theme toggle (before settings screen exists)
- Search for hardcoded `Colors.*`, `Color(0xFF...)`, or `Theme.of(context)` calls that may need dark-theme adjustments
- `lib/src/presentation/widgets/post_card.dart`, `comment_tree.dart`, `feed_screen_scaffold.dart` — likely have custom colors

## Implementation notes
- `MaterialApp.theme` = light, `MaterialApp.darkTheme` = dark, `MaterialApp.themeMode` = `ThemeMode.system` / `.light` / `.dark`
- AMOLED dark theme: same as dark but scaffold/card backgrounds use pure black instead of dark grey; use a separate `ThemeMode` or custom provider switching between `darkTheme` and `amoledDarkTheme` parameters
- Add `ThemeMode` enum to settings, persist as string
- Check for `Theme.of(context)` usage vs hardcoded colors — prefer theme colors (e.g. `Theme.of(context).colorScheme.surface` over `Colors.white`)
- Card backgrounds (`Card` widget) automatically follow theme via `elevation` and `color`
- `Icon` color: use theme foreground colors
- `Text` styles: use theme `TextTheme` for consistent light/dark

## Dependencies
- Settings persistence via `SharedPreferences` (already initialized in `lib/main.dart`)
- In-app settings screen (handoff #1) for the toggle — or add toggle directly in Account screen as interim

## Non-goals
- Custom accent color picker (future)
- Per-subreddit theme overrides
- Dynamic color (Material You) — add later if targeting Android

## Manual test steps
1. `flutter run`
2. Navigate to Account → Settings (or Account if no settings yet)
3. Tap "Theme" — choose "Dark"
4. Verify dark theme applies throughout: feed, post detail, comments, inbox, search, profiles, submit, account
5. Switch to "AMOLED Dark" — verify pure black backgrounds
6. Switch to "Light" — verify original light theme
7. Switch to "System" — verify follows system dark mode toggle
8. Kill and restart app — verify theme persists
