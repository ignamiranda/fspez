# User saved, overview, and hidden listings are OverviewItem listings, not Feed

Reddit's `/user/{name}/saved`, `/user/{name}/overview`, and `/user/{name}/hidden` endpoints return mixed t3 (Post) and t1 (Comment) children in a single paginated listing. `FeedKind.saved` treated saved items as a `Feed` of `List<Post>`, which silently dropped saved comments and misrepresented the API shape. The glossary defines `Feed` as "any paginated list of post previews rendered as cards" — a definition that inherently excludes mixed-kind listings. A new abstraction was needed for surfaces that genuinely mix posts and comments.

**Considered Options**:
- **Keep `saved` as `FeedKind`, posts only**: Accept the gap vs. Reddit parity. Rejected because saved comments are a core Reddit feature and the silent data loss is a bug, not a design choice.
- **Separate `SavedNotifier`, `OverviewNotifier`, and `HiddenNotifier`**: Each surface gets its own concrete notifier returning `List<OverviewItem>`. Rejected because the three endpoints share identical pagination shape and response structure — three parallel stacks would duplicate the same fetch-and-parse logic.
- **Single `OverviewNotifier` parameterized by source**: One notifier with a source parameter (`overview | saved | hidden`) that always returns `List<OverviewItem>`. The pagination mechanics are identical; only the endpoint path and UI label differ. Selected for DRY correctness.

**Consequences**: `FeedKind.saved` will be removed from `FeedKind`. When the saved listing screen is built, it will use `OverviewItem` (not `Post`) and will be backed by `OverviewNotifier` (not `FeedPageNotifier`). `FeedKind.user` remains valid because `/user/{name}/submitted` is kind-homogeneous (t3 only).