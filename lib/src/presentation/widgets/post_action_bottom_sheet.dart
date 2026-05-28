import 'package:flutter/material.dart';

/// A single action item in a post/comment action sheet.
class PostActionSheetItem {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback onTap;

  const PostActionSheetItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });
}

/// A section of actions in the sheet, visually separated by a divider.
class PostActionSheetSection {
  final List<PostActionSheetItem> items;

  const PostActionSheetSection({required this.items});

  bool get isEmpty => items.isEmpty;
}

/// Shows a Material 3 bottom sheet with grouped post/comment actions.
///
/// Sections are displayed with dividers between them. Destructive items
/// are rendered in the error color. Each item fills at least 48dp height
/// for comfortable touch targets.
///
/// The sheet dismisses before invoking [PostActionSheetItem.onTap], so
/// callers can show confirmation dialogs or navigate without the sheet
/// overlapping.
void showPostActionSheet(
  BuildContext context, {
  required List<PostActionSheetSection> sections,
}) {
  final nonEmpty = sections.where((s) => s.items.isNotEmpty).toList();
  if (nonEmpty.isEmpty) return;

  showModalBottomSheet<void>(
    context: context,
    builder: (_) => _PostActionSheetContent(sections: nonEmpty),
  );
}

class _PostActionSheetContent extends StatelessWidget {
  final List<PostActionSheetSection> sections;

  const _PostActionSheetContent({required this.sections});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: cs.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Action sections
          for (var i = 0; i < sections.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: cs.outlineVariant,
              ),
            for (final item in sections[i].items) _ActionSheetTile(item: item),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ActionSheetTile extends StatelessWidget {
  final PostActionSheetItem item;

  const _ActionSheetTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = item.isDestructive ? cs.error : cs.onSurface;

    return ListTile(
      leading: Icon(item.icon, color: color),
      title: Text(
        item.label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      minTileHeight: 48,
      shape: const RoundedRectangleBorder(),
      onTap: () {
        Navigator.of(context).pop();
        item.onTap();
      },
    );
  }
}
