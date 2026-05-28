import 'package:flutter/material.dart';

/// App-wide theme mode, persisted in SharedPreferences.
///
/// Extends Flutter's [ThemeMode] with an AMOLED (pure black) dark option.
enum AppThemeMode {
  system('system', 'System default'),
  light('light', 'Light'),
  dark('dark', 'Dark'),
  amoled('amoled', 'AMOLED Dark');

  final String persistKey;
  final String label;

  const AppThemeMode(this.persistKey, this.label);

  /// Convert to Flutter's [ThemeMode] for [MaterialApp.themeMode].
  ///
  /// AMOLED maps to [ThemeMode.dark]; the caller switches the
  /// [MaterialApp.darkTheme] reference between the regular dark and AMOLED
  /// ThemeData based on [this] value.
  ThemeMode toThemeMode() {
    switch (this) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
      case AppThemeMode.amoled:
        return ThemeMode.dark;
    }
  }

  static AppThemeMode fromPersistKey(String? key) {
    if (key == null) return AppThemeMode.system;
    for (final mode in AppThemeMode.values) {
      if (mode.persistKey == key) return mode;
    }
    return AppThemeMode.system;
  }
}
