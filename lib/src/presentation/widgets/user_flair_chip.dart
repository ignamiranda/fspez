import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/models/user_flair.dart';

/// A small, non-interactive pill that renders a user's community flair next to
/// their username in posts, comments, and messages.
///
/// Colors come from the Reddit API when present; otherwise falls back to a
/// neutral surface-variant chip. Long flair text is truncated with ellipsis.
class UserFlairChip extends StatelessWidget {
  final UserFlair flair;

  const UserFlairChip({super.key, required this.flair});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = _parseBackground(theme);
    final fg = _resolveForeground(bg);

    return Container(
      constraints: const BoxConstraints(maxWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        flair.text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelMedium?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
    );
  }

  Color _parseBackground(ThemeData theme) {
    final parsed = _hexToColor(flair.backgroundColor);
    return parsed ?? theme.colorScheme.surfaceContainerHighest;
  }

  /// Picks a readable foreground color using WCAG-relative-luminance logic.
  ///
  /// When the API provides an explicit text-color keyword (`light`/`dark`) we
  /// trust it. Otherwise we fall back to a luminance check against the resolved
  /// background — white for dark backgrounds, dark text for light ones.
  Color _resolveForeground(Color background) {
    final tc = flair.textColor;
    if (tc == 'light') return Colors.white;
    if (tc == 'dark') return Colors.black87;
    // Auto-contrast: WCAG relative luminance (0 = black, 1 = white).
    final luminance = _relativeLuminance(background);
    // Luminance threshold: 0.179 produces ~4.5:1 contrast with pure white.
    return luminance > 0.179 ? Colors.black87 : Colors.white;
  }

  /// WCAG 2.1 relative luminance of a color.
  /// WCAG 2.1 relative luminance of a color.
  static double _relativeLuminance(Color c) {
    final r = _linearize(c.r);
    final g = _linearize(c.g);
    final b = _linearize(c.b);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// sRGB channel (0-1) → linear value.
  static double _linearize(double v) {
    return (v <= 0.04045) ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) as double;
  }

  /// Parses `#RRGGBB` or `#AARRGGBB` hex strings (with or without `#`).
  static Color? _hexToColor(String? raw) {
    if (raw == null) return null;
    var value = raw.trim();
    if (value.startsWith('#')) value = value.substring(1);
    if (value.length == 6) value = 'FF$value';
    if (value.length != 8) return null;
    final parsed = int.tryParse(value, radix: 16);
    if (parsed == null) return null;
    return Color(parsed);
  }
}
