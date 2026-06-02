import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/enums/app_theme_mode.dart';
import '../domain/enums/comment_sort.dart';
import '../domain/enums/feed_density.dart';
import 'auth_providers.dart';

class AppSettings {
  final AppThemeMode themeMode;
  final CommentSort? defaultCommentSort;
  final bool showAwards;
  final bool nsfwBlur;
  final bool spoilerBlur;
  final FeedDensity feedDensity;
  final bool prefetchMedia;

  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.defaultCommentSort,
    this.showAwards = true,
    this.nsfwBlur = true,
    this.spoilerBlur = true,
    this.feedDensity = FeedDensity.comfortable,
    this.prefetchMedia = true,
  });

  AppSettings copyWith({
    AppThemeMode? themeMode,
    CommentSort? defaultCommentSort,
    bool? showAwards,
    bool? nsfwBlur,
    bool? spoilerBlur,
    FeedDensity? feedDensity,
    bool? prefetchMedia,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      defaultCommentSort: defaultCommentSort ?? this.defaultCommentSort,
      showAwards: showAwards ?? this.showAwards,
      nsfwBlur: nsfwBlur ?? this.nsfwBlur,
      spoilerBlur: spoilerBlur ?? this.spoilerBlur,
      feedDensity: feedDensity ?? this.feedDensity,
      prefetchMedia: prefetchMedia ?? this.prefetchMedia,
    );
  }
}

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  static const _themeModeKey = 'settings.themeMode';
  static const _defaultCommentSortKey = 'settings.defaultCommentSort';
  static const _showAwardsKey = 'settings.showAwards';
  static const _nsfwBlurKey = 'settings.nsfwBlur';
  static const _spoilerBlurKey = 'settings.spoilerBlur';
  static const _feedDensityKey = 'settings.feedDensity';
  static const _prefetchMediaKey = 'settings.prefetchMedia';

  final SharedPreferences _prefs;

  AppSettingsNotifier(this._prefs) : super(_load(_prefs));

  static AppSettings _load(SharedPreferences prefs) {
    return AppSettings(
      themeMode: AppThemeMode.fromPersistKey(prefs.getString(_themeModeKey)),
      defaultCommentSort: _commentSortFromNullable(
        prefs.getString(_defaultCommentSortKey),
      ),
      showAwards: prefs.getBool(_showAwardsKey) ?? true,
      nsfwBlur: prefs.getBool(_nsfwBlurKey) ?? true,
      spoilerBlur: prefs.getBool(_spoilerBlurKey) ?? true,
      feedDensity: FeedDensity.fromPersistKey(
        prefs.getString(_feedDensityKey),
      ),
      prefetchMedia: prefs.getBool(_prefetchMediaKey) ?? true,
    );
  }

  /// Returns `null` when no stored preference (use Reddit default).
  static CommentSort? _commentSortFromNullable(String? value) {
    if (value == null) return null;
    for (final sort in CommentSort.values) {
      if (sort.queryValue == value) return sort;
    }
    return null;
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    await _prefs.setString(_themeModeKey, mode.persistKey);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setDefaultCommentSort(CommentSort? sort) async {
    if (sort != null) {
      await _prefs.setString(_defaultCommentSortKey, sort.queryValue);
    } else {
      await _prefs.remove(_defaultCommentSortKey);
    }
    state = state.copyWith(defaultCommentSort: sort);
  }

  Future<void> setShowAwards(bool value) async {
    await _prefs.setBool(_showAwardsKey, value);
    state = state.copyWith(showAwards: value);
  }

  Future<void> setNsfwBlur(bool value) async {
    await _prefs.setBool(_nsfwBlurKey, value);
    state = state.copyWith(nsfwBlur: value);
  }

  Future<void> setSpoilerBlur(bool value) async {
    await _prefs.setBool(_spoilerBlurKey, value);
    state = state.copyWith(spoilerBlur: value);
  }

  Future<void> setFeedDensity(FeedDensity density) async {
    await _prefs.setString(_feedDensityKey, density.persistKey);
    state = state.copyWith(feedDensity: density);
  }

  Future<void> setPrefetchMedia(bool value) async {
    await _prefs.setBool(_prefetchMediaKey, value);
    state = state.copyWith(prefetchMedia: value);
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier(ref.watch(sharedPrefsProvider));
});
