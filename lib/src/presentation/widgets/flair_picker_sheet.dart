import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/models/flair_option.dart';
import 'bottom_sheet_menu.dart';

/// Opens a modal bottom sheet to pick a post flair for the current subreddit.
///
/// Returns the selected [FlairOption] or null if dismissed.
Future<FlairOption?> showFlairPickerSheet(
  BuildContext context, {
  required List<FlairOption> options,
  required FlairOption? currentSelection,
}) {
  return showModalBottomSheet<FlairOption>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      final maxHeight = MediaQuery.sizeOf(ctx).height * 0.7;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DragHandle(),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Post flair',
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                  ),
                ),
                const Divider(height: 1),
                const SizedBox(height: 4),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      // "None" option to clear selection.
                      _FlairPickerTile(
                        flair: null,
                        isSelected: currentSelection == null,
                        onTap: () => Navigator.of(ctx).pop(null),
                      ),
                      ...options.map(
                        (flair) => _FlairPickerTile(
                          flair: flair,
                          isSelected: currentSelection?.flairTemplateId ==
                              flair.flairTemplateId,
                          onTap: () => Navigator.of(ctx).pop(flair),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _FlairPickerTile extends StatelessWidget {
  final FlairOption? flair;
  final bool isSelected;
  final VoidCallback onTap;

  const _FlairPickerTile({
    this.flair,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        size: 20,
      ),
      title: flair != null ? _FlairChip(flair: flair!) : const Text('None'),
      trailing: flair?.backgroundColor != null
          ? Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Color(flair!.backgroundColor!),
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.outlineVariant),
              ),
            )
          : null,
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      shape: isSelected
          ? Border(left: BorderSide(color: colorScheme.primary, width: 3))
          : null,
    );
  }
}

/// Small pill showing the flair text with its actual background/text colors.
class _FlairChip extends StatelessWidget {
  final FlairOption flair;

  const _FlairChip({required this.flair});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = flair.backgroundColor != null
        ? Color(flair.backgroundColor!)
        : theme.colorScheme.surfaceContainerHighest;
    final fg = _resolveForeground(bg, theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        flair.displayText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelLarge?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
    );
  }

  Color _resolveForeground(Color background, ThemeData theme) {
    if (flair.textColor != null) {
      return Color(flair.textColor!);
    }
    // Auto-contrast for dark/light backgrounds (same logic as UserFlairChip).
    final luminance = _relativeLuminance(background);
    return luminance > 0.179 ? Colors.black87 : Colors.white;
  }

  static double _relativeLuminance(Color c) {
    final r = _linearize(c.r);
    final g = _linearize(c.g);
    final b = _linearize(c.b);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double _linearize(double v) {
    return (v <= 0.04045) ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) as double;
  }
}
