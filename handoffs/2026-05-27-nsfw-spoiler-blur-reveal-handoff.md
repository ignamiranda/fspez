# Handoff: NSFW/spoiler blur and reveal controls

## Approved mobile safety/content quality improvement

Implement **inline NSFW and spoiler blur/reveal controls** for feed and detail media.

## Current goal

Implement features to reach feature parity with the official Reddit mobile app, prioritizing mobile-app parity, mobile-quality UX, architecture, reliability, and overall app quality.

## Why this improvement

Reddit mobile users expect respectful handling of sensitive content. NSFW and spoiler posts should be clearly labeled, visually protected in feeds, and easy to reveal intentionally. This improves safety, trust, and official-app parity.

## Existing related implementation

Inspect these areas first:

- `lib/src/domain/models/post.dart`
  - Check existing NSFW/spoiler fields parsed from Reddit listings.
- `lib/src/data/api_responses.dart`
  - Verify JSON fields such as `over_18`, `spoiler`, thumbnail/media metadata.
- `lib/src/presentation/widgets/post_card.dart`
  - Feed card media preview and labels.
- `lib/src/presentation/widgets/media_viewer.dart`
  - Fullscreen media reveal behavior.
- `lib/src/presentation/screens/post_detail_screen.dart`
  - Detail header/media rendering.
- `lib/main.dart`
  - SharedPreferences initialization for local settings.

Related approved handoffs:

- `handoffs/2026-05-27-in-app-settings-screen-handoff.md`
- `handoffs/2026-05-27-adaptive-image-scaling-handoff.md`
- `handoffs/2026-05-27-gesture-first-media-browsing-handoff.md`
- `handoffs/2026-05-27-first-run-account-feed-setup-handoff.md`

## Suggested implementation scope

Smallest useful vertical slice:

1. Ensure post model/parsing exposes NSFW and spoiler flags.
2. Blur or obscure inline media previews for NSFW/spoiler posts in feeds.
3. Show clear labels: “NSFW”, “Spoiler”, or both.
4. Tap-to-reveal inline preview for the current session/view.
5. Apply the same protection when opening media fullscreen unless already revealed from the card.
6. Add settings only if settings infrastructure exists:
   - Blur NSFW media by default.
   - Blur spoiler media by default.
   - Possibly “Always reveal” for users who opt in.

## UX requirements

- Blurred content should still communicate that media exists.
- Labels must be readable on top of blurred/dimmed media.
- Reveal action should be intentional and touch-friendly.
- Revealing one post should not automatically reveal all sensitive posts unless the user changed a setting.
- Text-only NSFW/spoiler posts should still show labels even if no media is blurred.
- Avoid hiding moderation/safety context; users should understand why content is obscured.

## Technical discovery needed

Before editing, inspect:

- Whether post API models already include `over_18` and `spoiler`.
- Current media widget boundaries and whether blur can be applied around a reusable media preview.
- Whether `ImageFiltered`, `BackdropFilter`, or overlay approaches fit current layout.
- How fullscreen media receives post context and whether sensitive flags are available there.
- Existing settings provider state if the settings handoff has been implemented first.

## Architecture guidance

- Keep sensitive-content policy in a small provider/helper rather than scattering `if (post.isNsfw)` checks everywhere.
- Keep reveal state local/session-scoped unless implementing a deliberate persisted preference.
- Coordinate with feed density and adaptive image work so overlays do not break layout.

## Deferred out of scope

- Age verification or account-level Reddit preference changes.
- Filtering/removing NSFW content from feeds entirely.
- Community-level content controls.
- Machine vision/content classification.
- Media download protection.

## Acceptance criteria

- NSFW and spoiler posts are visibly labeled.
- Sensitive media previews are blurred/obscured by default.
- User can tap to reveal a specific post/media item.
- Fullscreen media respects blur/reveal state.
- Settings are integrated only if they are functional and persisted.
- Existing media viewing, galleries, and video aspect ratio behavior do not regress.

## Validation

Run after implementation:

- `dart format` on touched Dart files.
- `flutter analyze`.
- `flutter test` if tests are added/changed.
- Manual `flutter run` checks:
  - Open a feed with NSFW and/or spoiler posts.
  - Confirm labels and blur appear.
  - Tap reveal and confirm media becomes visible.
  - Open fullscreen and confirm reveal behavior is consistent.
  - Change settings if implemented and confirm persistence after restart.

## Suggested skills / agents

- Use `@designer` for mobile overlay/reveal interaction polish.
- Reuse explorer session `exp-2 Check post edit implementation` for post card/media viewer context if needed.
- Use `@fixer` for bounded implementation after model fields and media boundaries are clear.
