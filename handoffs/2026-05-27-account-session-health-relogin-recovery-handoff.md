# Handoff: Account/session health and re-login recovery

## Approved mobile reliability improvement

Implement **account/session health and re-login recovery** for expired or partially broken Reddit cookie sessions.

## Current goal

Implement features to reach feature parity with the official Reddit mobile app, prioritizing mobile-app parity, mobile-quality UX, architecture, reliability, and overall app quality.

## Why this improvement

The app uses cookie-only Reddit auth. Cookies can expire, become incomplete, or fail on specific write endpoints. Mobile users should see clear recovery paths instead of mysterious failed votes, saves, submits, inbox actions, or moderation operations.

## Existing related implementation

Inspect these areas first:

- `lib/src/presentation/screens/auth_webview_screen.dart`
  - Existing WebView login/session capture flow.
- `lib/src/presentation/screens/account_screen.dart`
  - Multi-account add/remove/switch/logout behavior.
- `lib/src/data/reddit_client.dart`
  - Low-level HTTP calls, error handling, endpoint domains, and modhash behavior.
- Auth/session repositories/providers under `lib/src/data/`.
- `lib/main.dart`
  - Startup and persisted account/session initialization.

Relevant project auth notes:

- Auth is cookie-only via WebView CDP (`Network.getCookies`, 10×500ms).
- `GET /api/me` provides modhash.
- No OAuth.
- Write endpoints have different domain/header/modhash requirements.
- Save/submit old Reddit flows are especially sensitive to full cookie + modhash/header requirements.

Related approved handoffs:

- `handoffs/2026-05-27-first-run-account-feed-setup-handoff.md`
- `handoffs/2026-05-27-centralize-thing-actions-handoff.md`
- `handoffs/2026-05-27-optimistic-action-undo-snackbars-handoff.md`
- `handoffs/2026-05-27-media-post-submission-handoff.md`

## Suggested implementation scope

Smallest useful vertical slice:

1. Add explicit session health checks at startup/account switch.
   - Verify current user with `/api/me` or existing equivalent.
   - Detect missing/expired modhash or invalid username/session.
2. Classify common auth failures from Reddit responses.
   - Expired session.
   - Missing modhash.
   - Forbidden endpoint due to cookie/header/domain issue.
   - Logged-out/anonymous state.
3. Surface a clear mobile recovery UI:
   - “Session expired” or “Reddit needs you to log in again”.
   - Re-login button using existing WebView auth.
   - Switch account.
   - Continue logged out where safe.
4. Route write-operation auth failures to the recovery flow or a consistent snackbar/sheet.
5. Preserve pending local UI state where practical; do not discard drafts or form text on re-login.

## UX requirements

- Do not show raw HTTP 403/401 messages to users.
- Make recovery action obvious and thumb-friendly.
- Avoid logging users out silently.
- Distinguish “not logged in” from “session expired”.
- If an action fails because auth expired, explain whether the user should retry after re-login.
- Multi-account users should be able to switch accounts from the recovery surface.

## Technical discovery needed

Before editing, inspect:

- Current stored account/session model and account switching lifecycle.
- How `RedditClient` reports status codes/errors today.
- Whether write notifiers already expose typed failures or only generic exceptions.
- Whether `/api/me` failures are already handled anywhere.
- How WebView auth returns to the previous screen.
- How modhash is refreshed and cached.

## Architecture guidance

- Introduce typed auth/session failure classification close to the data layer.
- Keep user-facing recovery UI in presentation layer.
- Avoid scattering `if statusCode == 403` checks across widgets.
- Coordinate with `centralize-thing-actions-handoff` so future actions can share recovery behavior.

## Deferred out of scope

- OAuth migration.
- Background token refresh beyond cookie/session verification.
- Push notification auth.
- Automatic password/account handling.
- Retrying irreversible actions without explicit user confirmation.

## Acceptance criteria

- Startup/account switch can detect an invalid or expired session.
- Common auth failures are mapped to clear user-facing recovery states.
- User can re-login through the existing WebView flow and return to the app.
- Write-action auth failures no longer appear as unexplained generic errors.
- Multi-account switch/logout behavior does not regress.

## Validation

Run after implementation:

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test` if tests are added/changed.
- Manual `flutter run` checks:
  - Launch with a valid account; confirm no false expired state.
  - Simulate invalid/expired cookies if practical; confirm recovery UI appears.
  - Re-login and confirm normal authenticated actions work again.
  - Trigger a write operation with broken auth and confirm clear recovery copy.
  - Switch accounts and confirm health state updates.

## Suggested skills / agents

- Use `reddit-api-auth` for endpoint/auth failure semantics if needed.
- Use `@oracle` if designing typed error/recovery architecture across client/notifiers.
- Reuse explorer session `exp-2 Check post edit implementation` for client/action context if needed.
- Use `@fixer` for bounded implementation after error-classification boundaries are chosen.
