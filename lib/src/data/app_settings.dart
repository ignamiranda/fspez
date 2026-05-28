import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/enums/comment_sort.dart';
import 'auth_providers.dart';

class AppSettings {
  /// `null` = use Reddit's default (confidence/Best).
  final CommentSort? defaultCommentSort;
  final bool showAwards;

  const AppSettings({
    this.defaultCommentSort,
    this.showAwards = true,
  });

  AppSettings copyWith({
    bool? showAwards,
  }) {
    return AppSettings(
      defaultCommentSort: defaultCommentSort,
      showAwards: showAwards ?? this.showAwards,
    );
  }
}

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  static const _defaultCommentSortKey = 'settings.defaultCommentSort';
  static const _showAwardsKey = 'settings.showAwards';

  final SharedPreferences _prefs;

  AppSettingsNotifier(this._prefs) : super(_load(_prefs));

  static AppSettings _load(SharedPreferences prefs) {
    final storedSort = prefs.getString(_defaultCommentSortKey);
    return AppSettings(
      defaultCommentSort: _commentSortFromNullable(storedSort),
      showAwards: prefs.getBool(_showAwardsKey) ?? true,
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

  Future<void> setDefaultCommentSort(CommentSort? sort) async {
    if (sort != null) {
      await _prefs.setString(_defaultCommentSortKey, sort.queryValue);
    } else {
      await _prefs.remove(_defaultCommentSortKey);
    }
    state = AppSettings(
      defaultCommentSort: sort,
      showAwards: state.showAwards,
    );
  }

  Future<void> setShowAwards(bool value) async {
    await _prefs.setBool(_showAwardsKey, value);
    state = AppSettings(
      defaultCommentSort: state.defaultCommentSort,
      showAwards: value,
    );
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier(ref.watch(sharedPrefsProvider));
});
