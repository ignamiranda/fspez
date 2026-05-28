# Post save to custom collections

## Scope
Allow users to save posts to named custom collections/categories instead of a single flat "Saved" list, matching official Reddit "Save to" / Collections feature.

## What to build
- Fetch user's existing collections/categories via Reddit API — verify endpoint (likely `/api/v1/me/saved_categories` or part of the save response)
- If no API endpoint exists, implement local-only collections via SharedPreferences (collections stored locally, posts mapped by fullname)
- In post overflow menu, change "Save" to show current collection or a "Save to..." submenu
- "Save to..." opens a picker showing existing collections + "New collection" option
- New collection: text input for name, create and save post to it
- Saved screen shows collections at top as tabs/pills, tapping shows only posts in that collection
- "All Saved" still shows everything
- Collections: create, rename, delete with confirmation
- Persist collections locally or server-side based on API availability

## Where to inspect
- `lib/src/presentation/screens/account_screen.dart` or saved screen — entry for saved collections
- `lib/src/presentation/screens/saved_screen.dart` — saved items display
- `lib/src/data/save_notifier.dart` — save/unsave logic
- `lib/src/data/reddit_client.dart` — check for collection/save-to-category endpoints

## Implementation notes
- Reddit's official save-to-collection API: search for recent changes — Reddit has been rolling out Collections slowly
- If API supports it: `POST /api/save` with `category=collection_name` parameter
- If API doesn't support it: store collections locally in SharedPreferences using JSON format:
  ```json
  {
    "collections": [
      {"id": "c1", "name": "Watch later", "postIds": ["t3_abc", "t3_def"]},
      {"id": "c2", "name": "Favorites", "postIds": ["t3_ghi"]}
    ]
  }
  ```
- Account-isolate collections (different collections per logged-in user)
- Collection creation within the save flow: show bottom sheet with list + "New collection" button
- Collection deletion: confirm dialog, move posts to "All Saved" (don't unsave them)
- Show collection name badge on saved posts in the saved screen

## Non-goals
- Server-side sync of local-only collections
- Sharing collections with other users
- Auto-categorization or smart collections
- Collection cover images or ordering

## Manual test steps
1. `flutter run`
2. Open any post → overflow → "Save to..."
3. Select "New collection" → type name → save
4. Verify post saved to that collection
5. Open another post → save to same collection
6. Navigate to Saved screen → verify collection tabs/pills appear
7. Tap collection tab → verify only posts in that collection shown
8. Tap "All Saved" → verify all saved posts shown
9. Create another collection, save posts to it
10. Delete a collection → verify posts move to All Saved, not unsaved
