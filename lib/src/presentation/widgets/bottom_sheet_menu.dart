import 'package:flutter/material.dart';

/// A single tappable action in a bottom sheet menu.
class BottomSheetAction {
  final IconData icon;
  final String label;
  final Color? iconColor;
  final VoidCallback onTap;
  final bool isDestructive;

  const BottomSheetAction({
    required this.icon,
    required this.label,
    this.iconColor,
    required this.onTap,
    this.isDestructive = false,
  });
}

/// Opens a modal bottom sheet with grouped action rows.
///
/// [primaryActions] appear in the top section (no header).
/// [authorActions] appear under an "Author" section header.
/// Both lists are omitted entirely when empty, so callers don't need to
/// filter empty sections themselves.
Future<void> showPostActionSheet(
  BuildContext context, {
  required List<BottomSheetAction> primaryActions,
  required List<BottomSheetAction> authorActions,
}) {
  final sections = <_SheetSection>[];
  if (primaryActions.isNotEmpty) {
    sections.add(_SheetSection(actions: primaryActions));
  }
  if (authorActions.isNotEmpty) {
    sections.add(_SheetSection(title: 'Author', actions: authorActions));
  }

  if (sections.isEmpty) return Future.value();

  return showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DragHandle(),
            const SizedBox(height: 8),
            for (var i = 0; i < sections.length; i++) ...[
              if (sections[i].title != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(16, i == 0 ? 0 : 4, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      sections[i].title!,
                      style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ),
              ...sections[i].actions.map((a) => _buildActionTile(ctx, a)),
              if (i < sections.length - 1) const Divider(height: 1),
            ],
          ],
        ),
      ),
    ),
  );
}

Widget _buildActionTile(BuildContext ctx, BottomSheetAction action) {
  final errorColor = Theme.of(ctx).colorScheme.error;
  return ListTile(
    leading: Icon(
      action.icon,
      color: action.isDestructive
          ? errorColor
          : action.iconColor ?? Theme.of(ctx).colorScheme.onSurface,
    ),
    title: Text(
      action.label,
      style: TextStyle(
        color: action.isDestructive ? errorColor : null,
        fontWeight: FontWeight.w500,
      ),
    ),
    onTap: () {
      Navigator.of(ctx).pop();
      action.onTap();
    },
    dense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
  );
}

/// Shows a modal bottom sheet with a radio-style list for selecting from
/// [values]. Uses [labelFn] to get the display text for each value.
/// The current selection is highlighted with [currentValue].
/// Returns the selected value, or null if dismissed.
Future<T?> showRadioBottomSheet<T>(
  BuildContext context, {
  required String title,
  required T currentValue,
  required List<T> values,
  required String Function(T) labelFn,
}) {
  return showModalBottomSheet<T>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DragHandle(),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
            ),
            const Divider(height: 1),
            RadioGroup<T>(
              groupValue: currentValue,
              onChanged: (value) {
                if (value != null) {
                  Navigator.of(ctx).pop(value);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: values
                    .map((v) => RadioListTile<T>(
                          title: Text(labelFn(v)),
                          value: v,
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 32,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .onSurfaceVariant
              .withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SheetSection {
  final String? title;
  final List<BottomSheetAction> actions;

  const _SheetSection({this.title, required this.actions});
}
