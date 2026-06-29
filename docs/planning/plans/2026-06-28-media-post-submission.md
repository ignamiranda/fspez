# Media Post Submission (Image/Gallery/Video)

## Objective

Add image, gallery, and video post creation to the Reddit client. Currently only text (`self`) and link posts work.

## Architecture

```
SubmitScreen (tabs: Text | Link | Image | Gallery | Video)
  ↓ calls
SubmitNotifier (extended with media state)
  ├── uploadImage() → MediaUploadClient.uploadToReddit()
  │     ├── requestUploadAsset() → POST /api/media/asset.json → UploadLease
  │     └── uploadToS3() → PUT bytes to S3 presigned URL
  └── submit() → RedditClient.submit() or submitGalleryPost()
```

### Auth
- Cookie + X-Modhash on `www.reddit.com` or `old.reddit.com`
- S3 upload is presigned URL — no auth needed
- Media asset requests use JSON Content-Type with cookie + modhash

### New endpoint: `/api/media/asset.json`
- POST JSON body: `{"filepath": "filename.jpg", "mimetype": "image/jpeg"}`
- Response: `{asset_id, asset_url, upload_url, args, status}`
- S3 upload: PUT raw bytes to `upload_url` with `Content-Type` matching mimetype

### Gallery submission: `/api/submit_gallery_post.json`
- POST form-encoded (same pattern as existing submit)
- Fields: `api_type=json`, `kind=gallery`, `sr`, `title`, `items` (JSON array `[{media_id, caption}]`), `sendreplies`, `nsfw`, `spoiler`

### Domain
- Media asset calls go to `www.reddit.com` (newer endpoint, may not be on old.reddit.com)
- S3 upload goes to `upload_url` directly (no Reddit auth)
- Gallery submission goes to `www.reddit.com/api/submit_gallery_post.json`

---

## Files to Modify

### 1. `pubspec.yaml`
- Add `file_picker: ^11.0.2`

### 2. `lib/src/data/http_transport.dart`
- Add `ApiEndpoint.mediaUpload` (for JSON POST to www.reddit.com with cookie + modhash + browser UA)
- Add `postJson()` method for JSON POST (step 1 of upload)
- Add `putBytes()` method for S3 upload (step 2)

### 3. `lib/src/data/reddit_client.dart`
- Add `requestUploadAsset(String filepath, String mimetype, SessionCookie)` → POST JSON to www.reddit.com/api/media/asset.json
- Add `submitGalleryPost(Map<String, String> fields, SessionCookie)` → POST form to www.reddit.com/api/submit_gallery_post.json

### 4. `lib/src/data/media_upload_response.dart` (NEW)
- `UploadLease` model: `assetId`, `assetUrl`, `uploadUrl`, `args` (Map), `status`

### 5. `lib/src/data/media_client.dart` (NEW)
- Orchestrates the two-step upload: lease request → S3 upload
- `MediaUploadClient` class:
  - constructor takes `RedditClient` (for API calls) + `http.Client` (for S3 PUT)
  - `uploadImage(Uint8List bytes, String filename, SessionCookie)` → UploadResult
  - `uploadVideo(Uint8List bytes, String filename, SessionCookie)` → UploadResult
  - `_requestAsset(String filepath, String mimetype, SessionCookie)` → UploadLease
  - `_uploadToS3(UploadLease, Uint8List)` → void

### 6. `lib/src/data/submit_notifier.dart`
- Extend `SubmitState` to include:
  - `activeTab` enum (text, link, image, gallery, video)
  - `List<PlatformFile> selectedFiles` — for gallery (multiple) or single image/video
  - `List<String> captions` — per-image captions in gallery
  - `List<String> uploadAssetIds` — asset IDs after upload
  - `double? uploadProgress` — overall progress
- Extend `SubmitNotifier` with:
  - `selectFiles(List<PlatformFile> files)` — store selected files
  - `updateCaption(int index, String caption)` — per-image caption
  - `setActiveTab(SubmitTab tab)` — change active tab
  - `submitMedia(MediaSubmitParams params)` — orchestrate upload+submit pipeline
  - Keep existing `submit()` method intact for text/link

### 7. `lib/src/data/write_providers.dart`
- Add `MediaUploadClient` provider (lives as long as sessionCookie exists)
- Add any needed additional providers

### 8. `lib/src/presentation/screens/submit_screen.dart`
- Refactor to use tab navigation (could use `TabBar` + `TabBarView`, or segmented buttons + conditional rendering like current Text/Link)
- Text tab: existing behavior (keep intact)
- Link tab: existing behavior (keep intact)
- Image tab: file picker (single, FileType.image) → thumbnail preview → title + subreddit fields → submit button
- Gallery tab: file picker (multiple, FileType.image) → grid of thumbnails with caption inputs → title + subreddit → submit
- Video tab: file picker (single, FileType.video) → video info (name, size) → title + subreddit → submit

### 9. `lib/src/domain/models/media_upload_result.dart` (NEW)
- Domain model for upload result: assetId, assetUrl

---

## Task Breakdown

### Task 1: Add file_picker dependency
**Files**: `pubspec.yaml`
- Add `file_picker: ^11.0.2` under dependencies
- Run `flutter pub get`
- Verify build passes

### Task 2: Add media upload models
**Files**:
- `lib/src/data/media_upload_response.dart` (NEW)
- `lib/src/domain/models/media_upload_result.dart` (NEW)

Create two models following existing patterns:
- `UploadLease` (data layer) — maps from `api/media/asset.json` response JSON
- `MediaUploadResult` (domain) — keeps EquatableMixin pattern

### Task 3: Add upload transport methods
**Files**: `lib/src/data/http_transport.dart`, `lib/src/data/reddit_client.dart`

HttpTransport changes:
- Add `ApiEndpoint.mediaUpload` case (www.reddit.com, JSON Content-Type, cookie + modhash, browser UA)
- Add `postJson(Uri uri, Map<String, dynamic> body, SessionCookie?)` method
- Add `putBytes(Uri uri, Uint8List bytes, Map<String, String> headers)` method

RedditClient changes:
- Add `requestUploadAsset(String filepath, String mimetype, SessionCookie)` → returns Map (raw JSON response)
- Add `submitGalleryPost(Map<String, String> fields, SessionCookie)` → similar to submit() but to www.reddit.com/api/submit_gallery_post.json

### Task 4: Create MediaUploadClient
**Files**: `lib/src/data/media_client.dart` (NEW)

```dart
class MediaUploadClient {
  final RedditClient _redditClient;
  final http.Client _httpClient;
  
  MediaUploadClient(this._redditClient, {http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();
  
  Future<MediaUploadResult> uploadImage(Uint8List bytes, String filename, SessionCookie session) async { ... }
  Future<MediaUploadResult> uploadVideo(Uint8List bytes, String filename, SessionCookie session) async { ... }
}
```

### Task 5: Extend SubmitNotifier
**Files**: `lib/src/data/submit_notifier.dart`

- Add `SubmitTab` enum (text, link, image, gallery, video)
- Extend `SubmitState` with tab-specific fields
- Add `submitMedia()` method that:
  1. For image/video: uploads file → gets asset_id → submits with kind=image/video
  2. For gallery: uploads each file → collects asset_ids → submits gallery post
- Keep existing `submit()` unchanged

### Task 6: Add providers
**Files**: `lib/src/data/write_providers.dart`

- Add `mediaUploadClientProvider` that creates MediaUploadClient
- Add `submitMediaNotifierProvider` if needed (or reuse submitProvider)

### Task 7: UI — SubmitScreen tabs
**Files**: `lib/src/presentation/screens/submit_screen.dart`

- Refactor from choice chips to `TabBar` + `TabBarView` with 4-5 tabs
- Text tab: keep existing fields
- Link tab: keep existing fields  
- Image tab: file picker button → thumbnail preview → title → subreddit → submit
- Gallery tab: multi-file picker → grid of thumbnails + caption fields → title → subreddit → submit
- Video tab: file picker button → video info display → title → subreddit → submit
- Reuse existing subreddit, title, and submit button patterns

### Task 8: Clean up and verify
- `dart format` on all touched files
- `flutter analyze` — no new warnings
- `flutter test` — all existing tests pass
- Manual check: existing Text/Link tabs work unchanged

---

## Dependencies between tasks

```
Task 1 (pubspec) ← Task 7 (needs file_picker)
Task 2 (models) ← Task 3 (transport) ← Task 4 (client) ← Task 5 (notifier) ← Task 7 (UI)
Task 6 (providers) ← Task 7
```

Actually:
- Tasks 1-6 can be done in sequence (back-end → front-end)
- Task 7 depends on 5 & 6 & 1
- Task 8 is final

## Parallelization

- Tasks 1 + 2 can run in parallel (pubspec + models are independent)
- Tasks 3 can start after 2
- Tasks 4 depends on 3
- Tasks 5 + 6 depend on 4
- Task 7 depends on 1, 5, 6 — but can start earlier if interfaces are agreed
