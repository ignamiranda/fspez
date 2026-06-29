# Rules

## 🔴 Non-negotiable

**No API key use ever.** The app must never embed, ship, or require an API key from any service (Reddit API, third-party services, etc.). This includes:
- Hardcoded keys in source
- Keys fetched at build time or runtime
- Keys required for the app to function

Exception: Local dev/debugging may use temporary session tokens (e.g., `REDDIT_SESSION` in `.env`) that never ship in builds or reach users.

## Workflow

- **Handoff storage**: When the `handoff` skill produces a handoff file, save it to `$env:TEMP`, not to `handoffs/` in the workspace. The `handoff` skill's instruction is authoritative. The project `handoffs/` dir is for pre-existing or human-authored handoffs only.
