# Architecture Deepening — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use plan-execution (Approach B) (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply 4 high-confidence architecture deepening refactors to reduce duplication, collapse shallow modules, and improve locality.

**Architecture:** Four independent refactors, each isolated to its own module tree. Run in order of risk (lowest first). After each, `flutter analyze` and `flutter test` must pass.

**Tech Stack:** Dart, Flutter, Riverpod

## Global Constraints

- **No API keys ever** — cookie-only auth must not break
- **No build_runner, no freezed, no codegen** — all models hand-written
- **All 270 tests must pass** after each task (`flutter test`)
- **`flutter analyze --no-pub` must be clean** after each task
- Preserve existing Riverpod provider patterns and naming conventions
- Preserve ADR-0004 (one-shot actions as local state notifiers, not Riverpod singletons)

---

### Task A: Remove orphaned Message model

**Files:**
- Delete: `lib/src/domain/models/message.dart`
- Test: no test changes needed (no tests import it)

**Interfaces:**
- Consumes: nothing
- Produces: nothing — pure deletion

- [x] Verify no imports exist (already confirmed: `message.dart` has zero imports)
- [ ] Delete `lib/src/domain/models/message.dart`
- [ ] Run `flutter test` to confirm nothing breaks
- [ ] Run `flutter analyze --no-pub` to confirm clean

---

### Task B: Collapse duplicate comment mapping into shared_parsers

**Files:**
- Modify: `lib/src/data/parsers/shared_parsers.dart` — add canonical `commentFromApi()` function
- Modify: `lib/src/data/comment_repository.dart` — replace `_parseComments`+`_commentFromApi` with call to `shared_parsers`
- Modify: `lib/src/data/user_repository.dart` — replace `_parseComment` with call to `shared_parsers`
- Delete: `lib/src/data/comment_parser.dart` — dead class
- Test files to modify:
  - `test/data/comment_parser_test.dart` — delete or adapt to test `commentFromApi` directly
  - `test/data/comment_repository_test.dart` — ensure tests still pass
  - `test/data/user_repository_test.dart` — ensure tests still pass

**Interfaces:**
- Consumes: `ApiComment` model (from `lib/src/data/api_responses/api_comment.dart`)
- Produces: `Comment` commentFromApi(ApiComment api, {List<Comment>? replies})
- Produces: `Comment` commentFromApiData(Map<String, dynamic> data) — for UserRepository which has raw JSON

**Detailed implementation:**

Step 1 — Add to `shared_parsers.dart`:
```dart
Comment commentFromApi(ApiComment api) {
  return Comment(
    id: api.id,
    body: api.body,
    author: api.author,
    score: api.score,
    vote: parseVoteDirection(api.likes),
    isSaved: api.saved,
    isSubmitter: api.isSubmitter,
    isModerator: api.distinguished == 'moderator',
    isStickied: api.stickied,
    awardCount: api.awardCount,
    createdAt: DateTime.fromMillisecondsSinceEpoch(api.createdUtc * 1000),
    postId: api.linkId,
    parentId: api.parentId,
    depth: api.depth,
    replies: api.replies.map(commentFromApi).toList(),
    isCollapsed: api.collapsed,
    authorFlair: UserFlair.fromApi(
      text: api.authorFlairText,
      richtext: api.authorFlairRichtext,
      backgroundColor: api.authorFlairBackgroundColor,
      textColor: api.authorFlairTextColor,
    ),
    subreddit: api.commentSubreddit,
    linkTitle: api.linkTitle,
    linkPermalink: api.linkPermalink,
  );
}

Comment commentFromApiData(Map<String, dynamic> data) {
  return commentFromApi(ApiComment.fromJson(data));
}
```

Step 2 — Replace `_commentFromApi` in `CommentRepository` with call to `commentFromApi`.
Step 3 — Replace `_parseComment` in `UserRepository` with call to `commentFromApiData`.
Step 4 — Delete `CommentParser` class and its test file.
Step 5 — Verify.

- [ ] **Step 1:** Add `commentFromApi()` and `commentFromApiData()` to `shared_parsers.dart`
- [ ] **Step 2:** Update `comment_repository.dart` — replace `_parseComments()` and `_commentFromApi()` to call shared_parsers
- [ ] **Step 3:** Update `user_repository.dart` — replace `_parseComment()` to call `commentFromApiData()`
- [ ] **Step 4:** Delete `lib/src/data/comment_parser.dart` and `test/data/comment_parser_test.dart`
- [ ] **Step 5:** Run `flutter test` and `flutter analyze --no-pub`

---

### Task C: Consolidate action notifiers into generic ActionNotifier

**Files:**
- Modify: `lib/src/data/write_operation_notifier.dart` — keep as-is, this is the base
- Create: `lib/src/data/action_providers.dart` — helper functions and generic providers
- Modify: `lib/src/data/write_providers.dart` — update provider declarations
- Modify: `lib/src/data/vote_notifier.dart` — remove, inline into generic
- Modify: `lib/src/data/save_notifier.dart` — remove
- Modify: `lib/src/data/hide_notifier.dart` — remove
- Modify: `lib/src/data/delete_notifier.dart` — remove
- Modify: `lib/src/data/edit_notifier.dart` — remove
- Modify: `lib/src/data/block_action_notifier.dart` — remove
- Modify: `lib/src/presentation/widgets/post_actions.dart` — update callers
- Modify: `lib/src/presentation/screens/post_detail_screen.dart` — update callers
- Modify: `lib/src/presentation/screens/user_profile_screen.dart` — update callers
- Modify: other screens/files that use these providers
- Test files to update:
  - `test/data/vote_notifier_test.dart` — adapt
  - `test/data/save_notifier_test.dart` — adapt
  - other test files as needed

**Detailed design:**

Keep `WriteOperationNotifier` as the abstract base. Instead of N subclasses, create one generic:

```dart
typedef ActionOperation<T> = Future<T> Function();

class ActionNotifier<V> extends WriteOperationNotifier<V> {
  final V Function(String key) defaultValue;
  final WriteErrorPolicy errorPolicy;

  ActionNotifier(
    super.redditClient,
    super.sessionCookie, {
    this.defaultValue = _defaultNull,
    this.errorPolicy = WriteErrorPolicy.revert,
  });

  static V _defaultNull<V>(String key) => null as V;

  Future<void> execute(
    String key,
    V optimisticValue,
    V? previousValue,
    ActionOperation apiCall,
  ) async {
    await write(key, optimisticValue, previousValue, apiCall, onError: errorPolicy);
  }

  V effectiveValue(String key, V original) => effective(key, original);
}
```

Provider pattern in write_providers.dart:
```dart
final actionVoteProvider = StateNotifierProvider.autoDispose<ActionNotifier<VoteDirection>, Map<String, VoteDirection>>((ref) {
  final client = ref.watch(redditClientProvider);
  final cookie = ref.watch(activeAccountProvider)?.sessionCookie;
  return ActionNotifier<VoteDirection>(client, cookie, errorPolicy: WriteErrorPolicy.keepOptimistic);
});
```

Each screen's vote, save, hide, delete, block, edit operations use the generic `ActionNotifier`.

Special cases:
- `EditNotifier` currently has its own `EditState { isSaving, error, success }` pattern. This can either be adapted to `ActionNotifier<bool>` with a different error handling approach, or kept as-is if the state model is too different. Recommend: adapt to use ActionNotifier — replace `EditState` with `Map<String, bool>` where true = saving/edited.
- `BlockActionNotifier` has `_accountIdCache` and `_resolveAccountId`. This is extra behavior beyond the generic pattern — can be handled separately. The block/unblock methods can be extracted as standalone helper functions that use `ActionNotifier` internally.

- [ ] **Step 1:** Create `ActionNotifier<V>` generic class in `lib/src/data/action_providers.dart` (or add to `write_operation_notifier.dart`)
- [ ] **Step 2:** Update `write_providers.dart` — replace per-action providers with `ActionNotifier`-based providers
- [ ] **Step 3:** Update all screen files that consume action providers — switch to generic API
- [ ] **Step 4:** Update test files — adapt vote/save/hide/delete/edit tests to work with ActionNotifier
- [ ] **Step 5:** Delete redundant notifier files: vote_notifier.dart, save_notifier.dart, hide_notifier.dart, delete_notifier.dart, edit_notifier.dart
- [ ] **Step 6:** Delete block_action_notifier.dart (after extracting account-id resolution as standalone helper)
- [ ] **Step 7:** Run `flutter test` and `flutter analyze --no-pub`

---

### Task D: Push media state out of SubmitScreen

**Files:**
- Modify: `lib/src/data/submit_notifier.dart` — add media state (selectedImage, galleryFiles, selectedVideo, captions), add file-picking validation logic
- Modify: `lib/src/presentation/screens/submit_screen.dart` — extract tab widgets, simplify to pure layout shell
- Create: `lib/src/presentation/widgets/submit_image_tab.dart` — extracted from SubmitScreen._buildImageTab
- Create: `lib/src/presentation/widgets/submit_gallery_tab.dart` — extracted from SubmitScreen._buildGalleryTab
- Create: `lib/src/presentation/widgets/submit_video_tab.dart` — extracted from SubmitScreen._buildVideoTab
- Test: no existing tests for SubmitScreen (UI test gap)

**Detailed design:**

Expand `SubmitState` to include:
```dart
class SubmitState {
  // Existing
  final bool isSubmitting;
  final String? error;
  final bool success;
  final List<FlairOption> flairOptions;
  final FlairOption? selectedFlair;
  final bool isFlairRequired;
  final bool isFetchingFlairs;

  // New media state
  final PlatformFile? selectedImage;
  final List<PlatformFile> galleryFiles;
  final List<String> galleryCaptions;
  final PlatformFile? selectedVideo;
}
```

Add methods to `SubmitNotifier`:
- `setImage(PlatformFile? file)`
- `setGalleryFiles(List<PlatformFile> files, List<String> captions)`
- `addGalleryFiles(List<PlatformFile> files)` + caption management
- `removeGalleryItem(int index)`
- `setVideo(PlatformFile? file)`
- `clearMedia()`

SubmitScreen becomes a thin shell with TabBar + TabBarView, each tab widget delegates to notifier.

- [ ] **Step 1:** Expand `SubmitState` in `submit_notifier.dart` with media state fields
- [ ] **Step 2:** Add media mutation methods to `SubmitNotifier`
- [ ] **Step 3:** Extract image tab widget into `lib/src/presentation/widgets/submit_image_tab.dart`
- [ ] **Step 4:** Extract gallery tab widget into `lib/src/presentation/widgets/submit_gallery_tab.dart`
- [ ] **Step 5:** Extract video tab widget into `lib/src/presentation/widgets/submit_video_tab.dart`
- [ ] **Step 6:** Simplify `SubmitScreen` to use extracted widgets and notifier for all state
- [ ] **Step 7:** Run `flutter test` and `flutter analyze --no-pub`

---

### Execution Order

Run tasks sequentially — each is independent but verifying incrementally reduces risk:

1. **Task A** (2 min) — trivial deletion
2. **Task B** (5 min) — safe refactor, test-covered
3. **Task C** (15 min) — larger refactor, multiple callers
4. **Task D** (15 min) — largest change, affects UI
5. Run full test suite + analyze as final verification
