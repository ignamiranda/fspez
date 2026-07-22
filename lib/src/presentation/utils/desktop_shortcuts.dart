import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Whether the app is running on a desktop platform where keyboard shortcuts
/// are applicable.
bool get isDesktopPlatform =>
    !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

/// Shows a help overlay dialog listing available keyboard shortcuts.
void showKeyboardShortcutHelp(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.keyboard, size: 22),
          SizedBox(width: 8),
          Text('Keyboard Shortcuts'),
        ],
      ),
      content: const SingleChildScrollView(
        child: _ShortcutHelpContent(),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Got it'),
        ),
      ],
    ),
  );
}

class _ShortcutHelpContent extends StatelessWidget {
  const _ShortcutHelpContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ShortcutGroup(
          theme: theme,
          title: 'Feed Navigation',
          shortcuts: const [
            ('J', 'Move down'),
            ('K', 'Move up'),
            ('Enter', 'Open selected post'),
          ],
        ),
        const SizedBox(height: 16),
        _ShortcutGroup(
          theme: theme,
          title: 'Post Actions',
          shortcuts: const [
            ('A', 'Upvote'),
            ('Z', 'Downvote'),
            ('S', 'Save / Unsave'),
          ],
        ),
        const SizedBox(height: 16),
        _ShortcutGroup(
          theme: theme,
          title: 'General',
          shortcuts: const [
            ('?', 'Show this help'),
          ],
        ),
      ],
    );
  }
}

class _ShortcutGroup extends StatelessWidget {
  final ThemeData theme;
  final String title;
  final List<(String, String)> shortcuts;

  const _ShortcutGroup({
    required this.theme,
    required this.title,
    required this.shortcuts,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...shortcuts.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Text(
                    s.$1,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(s.$2),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
