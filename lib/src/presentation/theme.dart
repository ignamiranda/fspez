import 'package:flutter/material.dart';

class FspezTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1565C0),
      brightness: Brightness.light,
    );
    return _build(colorScheme);
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1565C0),
      brightness: Brightness.dark,
    );
    return _build(colorScheme);
  }

  static ThemeData _build(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,

      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: colorScheme.surfaceTint,
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSecondaryContainer,
            );
          }
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              size: 22,
              color: colorScheme.onSecondaryContainer,
            );
          }
          return IconThemeData(
            size: 22,
            color: colorScheme.onSurfaceVariant,
          );
        }),
      ),

      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: colorScheme.shadow,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 0.5,
        space: 1,
      ),

      textTheme: const TextTheme(
        displayLarge: const TextStyle(fontWeight: FontWeight.w700),
        displayMedium: const TextStyle(fontWeight: FontWeight.w700),
        displaySmall: const TextStyle(fontWeight: FontWeight.w600),
        headlineLarge: const TextStyle(fontWeight: FontWeight.w700),
        headlineMedium: const TextStyle(fontWeight: FontWeight.w600),
        headlineSmall: const TextStyle(fontWeight: FontWeight.w600),
        titleLarge: const TextStyle(fontWeight: FontWeight.w700),
        titleMedium: const TextStyle(fontWeight: FontWeight.w600),
        titleSmall: const TextStyle(fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(fontWeight: FontWeight.w400),
        bodyMedium: const TextStyle(fontWeight: FontWeight.w400),
        bodySmall: const TextStyle(fontWeight: FontWeight.w400),
        labelLarge: const TextStyle(fontWeight: FontWeight.w600),
        labelMedium: const TextStyle(fontWeight: FontWeight.w500),
        labelSmall: const TextStyle(fontWeight: FontWeight.w500),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 3,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
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
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        circularTrackColor: colorScheme.surfaceContainerHighest,
      ),

      iconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant,
        size: 22,
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
