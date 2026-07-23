# Split SubmitNotifier into smaller modules

This project does not split `SubmitNotifier` (392 lines) into separate `FlairNotifier` and `MediaPickerState` modules.

## Why this is out of scope

The `SubmitNotifier` monolith is only consumed by `SubmitScreen` — there is exactly one consumer for all its state. Splitting it would add 2+ new files, new provider declarations, and new import chains without reducing coupling at the consumer level. The screen would still need to compose the same three pieces.

However, two specific pain points in the current design are worth tracking separately:

1. **File I/O inside the notifier**: `submitImage()`, `submitVideo()`, and `submitGallery()` call `File(file.path!).readAsBytes()` internally, coupling unit tests to the filesystem. The notifier should accept `Uint8List` and let the caller (submit screen / file picker) read the file. This change would improve testability without restructuring state.

2. **`SubmitState.copyWith` 15 parameters**: The state model grows with every visual concern. Adding booleans like `clearImage`, `clearVideo`, `clearGallery` alongside real fields creates a confusing API. A `copyWith` that accepts nullable fields would be cleaner, though without codegen this is a manual maintenance cost.

If the submit screen gains more features that share flair or media state (e.g., editing a post with media, crossposting with flair), the split would pay off. Until then, the monolith is cheaper to keep.

## Prior requests

- #80 — "Split SubmitNotifier into FlairNotifier, MediaPickerState, and submission orchestration"
