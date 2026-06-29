import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'feed_pagination.dart';

/// A cached first-page feed entry with its timestamp.
class CachedFeedEntry {
  final Map<String, dynamic> data;
  final DateTime cachedAt;

  const CachedFeedEntry({required this.data, required this.cachedAt});

  bool isOlderThan(Duration duration) {
    return DateTime.now().difference(cachedAt) > duration;
  }
}

/// SharedPreferences-backed cache for first-page feed JSON responses.
///
/// Keys are isolated per account id (or `anon`) and per [FeedPageConfig].
/// Each entry stores the raw API JSON string plus a millisecond-precision
/// timestamp used for staleness checks.
///
/// This is intentionally narrow — caches only the first page and uses
/// [SharedPreferences] to avoid adding persistence dependencies.
class FeedCache {
  final SharedPreferences _prefs;
  static const _prefix = 'feed_cache_v1';
  static const staleAfter = Duration(minutes: 30);

  FeedCache(this._prefs);

  String _key(String accountId, FeedPageConfig config) {
    final parts = [
      _prefix,
      Uri.encodeComponent(accountId),
      Uri.encodeComponent(config.kind.name),
      Uri.encodeComponent(config.sort.name),
      if (config.identifier != null && config.identifier!.isNotEmpty)
        Uri.encodeComponent(config.identifier!),
    ];
    return parts.join('.');
  }

  /// Retrieves a cached feed entry, or `null` on cache miss.
  CachedFeedEntry? get(String accountId, FeedPageConfig config) {
    final key = _key(accountId, config);
    final json = _prefs.getString(key);
    final timestamp = _prefs.getInt('$key.ts');
    if (json == null || timestamp == null) return null;
    try {
      final decoded = jsonDecode(json);
      if (decoded is! Map<String, dynamic>) return null;
      return CachedFeedEntry(
        data: decoded,
        cachedAt: DateTime.fromMillisecondsSinceEpoch(timestamp),
      );
    } catch (_) {
      return null;
    }
  }

  /// Stores a raw API JSON response string for the given account + config.
  void set(String accountId, FeedPageConfig config, Map<String, dynamic> json) {
    final key = _key(accountId, config);
    _prefs.setString(key, jsonEncode(json));
    _prefs.setInt('$key.ts', DateTime.now().millisecondsSinceEpoch);
  }

  /// Removes the cached entry for the given account + config.
  void remove(String accountId, FeedPageConfig config) {
    final key = _key(accountId, config);
    _prefs.remove(key);
    _prefs.remove('$key.ts');
  }

  /// Removes all cached feed entries for a specific account.
  void clearForAccount(String accountId) {
    final prefix = '$_prefix.${Uri.encodeComponent(accountId)}.';
    final keys = _prefs.getKeys().where((k) => k.startsWith(prefix)).toList();
    for (final key in keys) {
      _prefs.remove(key);
    }
  }
}
