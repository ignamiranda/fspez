import 'package:flutter/material.dart';

class FspezTheme {
  static const _redditOrange = Color(0xFFFF4500);
  static const _downvoteBlue = Color(0xFF1976D2);
  static const _downvoteBlueDark = Color(0xFF7193FF);

  static ThemeData light() {
    final colorScheme = ColorScheme.light(
      primary: _redditOrange,
      onPrimary: Colors.white,
      primaryContainer: _redditOrange.withValues(alpha: 0.15),
      onPrimaryContainer: const Color(0xFF872000),
      secondary: _downvoteBlue,
      onSecondary: Colors.white,
      surface: const Color(0xFFFFFFFF),
      onSurface: const Color(0xFF1A1A1B),
      surfaceContainerHighest: const Color(0xFFF6F7F8),
      onSurfaceVariant: const Color(0xFF6B6B6B),
      outline: const Color(0xFFEDEFF1),
      outlineVariant: const Color(0xFFEDEFF1),
      error: const Color(0xFFD32F2F),
    );
    return _build(colorScheme, Brightness.light);
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.dark(
      primary: _redditOrange,
      onPrimary: Colors.white,
      primaryContainer: _redditOrange.withValues(alpha: 0.25),
      onPrimaryContainer: const Color(0xFFFFD4C2),
      secondary: _downvoteBlueDark,
      onSecondary: const Color(0xFF1A1A1B),
      surface: const Color(0xFF1A1A1B),
      onSurface: const Color(0xFFD7DADC),
      surfaceContainerHighest: const Color(0xFF272729),
      onSurfaceVariant: const Color(0xFF949596),
      outline: const Color(0xFF343536),
      outlineVariant: const Color(0xFF343536),
      error: const Color(0xFFCF6679),
    );
    return _build(colorScheme, Brightness.dark);
  }

  /// AMOLED dark theme — pure black backgrounds for OLED screens.
  static ThemeData amoled() {
    final colorScheme = ColorScheme.dark(
      primary: _redditOrange,
      onPrimary: Colors.white,
      primaryContainer: _redditOrange.withValues(alpha: 0.25),
      onPrimaryContainer: const Color(0xFFFFD4C2),
      secondary: _downvoteBlueDark,
      onSecondary: Colors.white,
      surface: const Color(0xFF000000),
      onSurface: const Color(0xFFD7DADC),
      surfaceContainerHighest: const Color(0xFF111111),
      onSurfaceVariant: const Color(0xFF949596),
      outline: const Color(0xFF222222),
      outlineVariant: const Color(0xFF222222),
      error: const Color(0xFFCF6679),
    );
    return _build(colorScheme, Brightness.dark);
  }

  static ThemeData _build(ColorScheme colorScheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.1),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            size: 20,
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          );
        }),
      ),
      cardTheme: CardThemeData(
        elevation: isDark ? 2 : 1,
        color: colorScheme.surface,
        shadowColor: Colors.transparent,
        margin: isDark ? const EdgeInsets.all(4) : const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isDark ? 12 : 8),
        ),
        clipBehavior: Clip.none,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 0.5,
        space: 0,
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurface,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurface,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurfaceVariant,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurfaceVariant,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            isDark ? colorScheme.surfaceContainerHighest : colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor:
            isDark ? const Color(0xFF333333) : const Color(0xFF323232),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide.none,
      ),
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        circularTrackColor: colorScheme.surfaceContainerHighest,
      ),
      iconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant,
        size: 20,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
        minVerticalPadding: 8,
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
    );
  }
}
