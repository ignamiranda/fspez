# Handoff: First-run account and feed setup flow

## Approved mobile onboarding improvement

Add a lightweight **first-run setup flow** for account and feed preferences.

## Current goal

Implement features to reach feature parity with the official Reddit mobile app, prioritizing mobile-app parity, mobile-quality UX, architecture, reliability, and overall app quality.

## Why this improvement

A polished mobile app should not drop new users into an empty or confusing state. First-run setup can help users understand login, choose their default browsing experience, and configure sensitive/media preferences before they start browsing.

## Existing related implementation

Inspect these areas first:

- `lib/main.dart`
  - SharedPreferences initialization and app startup.
- `lib/src/presentation/app.dart`
  - Root shell and bottom navigation.
- `lib/src/presentation/screens/auth_webview_screen.dart`
  - WebView login flow.
- `lib/src/presentation/screens/account_screen.dart`
  - Account add/switch/logout behavior.
- `lib/src/presentation/screens/feed_screen.dart`
  - Default feed and sort behavior.
- Existing settings/preferences code if `in-app-settings-screen-handoff` has been implemented before this.

Related approved handoffs:

- `handoffs/2026-05-27-in-app-settings-screen-handoff.md`
- `handoffs/2026-05-27-feed-density-modes-handoff.md`
- `handoffs/2026-05-27-gesture-first-media-browsing-handoff.md`
- `handoffs/2026-05-27-bottom-sheet-action-menus-handoff.md`

## Suggested implementation scope

Smallest useful vertical slice:

1. Track whether first-run setup has been completed in local preferences.
2. Show setup on first launch only, with a clear skip option.
3. Include login prompt:
   - Continue logged out.
   - Log in via existing WebView auth.
4. Let user choose default feed:
   - Home when logged in.
   - Popular.
   - All, if supported and appropriate.
5. Let user choose basic mobile browsing preferences if implemented:
   - Feed density.
   - Media autoplay/display preference.
   - NSFW visibility if supported by existing API/settings.
6. Show brief gesture/action tips after setup or on first media/post interaction.

## UX requirements

- Setup must be skippable.
- Avoid a long wizard; keep it 2–4 lightweight steps.
- Do not block logged-out browsing.
- Do not expose preferences that do nothing yet.
- Existing users should not be forced through setup after an app update unless the completion flag is absent and migration logic intentionally handles it.
- Provide a way to revisit relevant preferences later through Settings/Account.

## Technical discovery needed

Before editing, inspect:

- Current account/session detection at startup.
- Current default feed selection and whether it is persisted.
- Whether settings infrastructure exists yet; if not, keep first-run preferences minimal.
- How navigation should route between setup, auth WebView, and the main shell.
- Whether auth WebView returning from login can continue setup cleanly.

## Architecture guidance

- Keep setup state in a small onboarding/settings provider, not scattered across screens.
- Reuse existing auth and settings flows rather than creating parallel login/preference logic.
- Treat onboarding as optional guidance; core app should still work if setup is skipped.

## Deferred out of scope

- Full personalization questionnaire.
- Community recommendation engine.
- Push notification permission flow unless native mobile targets and notification infrastructure exist.
- A/B testing or analytics.
- Forced account creation/login.

## Acceptance criteria

- First launch shows setup; completed/skipped setup does not show again.
- User can log in from setup using existing auth flow or continue logged out.
- Selected default feed/preference values persist and affect the main app where implemented.
- Setup can be skipped without breaking navigation.
- Existing account switching/auth behavior does not regress.

## Validation

Run after implementation:

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test` if tests are added/changed.
- Manual `flutter run` checks:
  - Fresh preferences: setup appears.
  - Skip setup: main app opens and setup does not reappear.
  - Complete setup: choices persist after restart.
  - Login from setup: auth flow returns cleanly.
  - Existing stored preferences/account: setup does not interrupt normal launch.

## Suggested agents

- Use `@designer` for mobile onboarding layout, copy, and flow polish.
- Reuse explorer session `exp-2 Check post edit implementation` only if needing existing app/feed/auth context.
- Use `@fixer` for bounded implementation after startup routing and settings ownership are clear.
- Use `@oracle` if startup/auth routing becomes ambiguous or risks regressions.
