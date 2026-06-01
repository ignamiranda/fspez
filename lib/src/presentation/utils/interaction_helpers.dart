import 'package:flutter/material.dart';
import '../../data/post_actions_service.dart';
import '../../domain/enums/vote_direction.dart';

void handleVote(
  PostActionsService actions,
  String fullname,
  VoteDirection direction,
) {
  actions.vote(fullname, direction);
}

Future<void> handleUnhide(
  PostActionsService actions,
  String fullname,
  BuildContext context, {
  Future<void> Function()? onUndo,
}) async {
  try {
    await actions.unhide(fullname);
    if (context.mounted) {
      final scaffold = ScaffoldMessenger.of(context);
      scaffold.hideCurrentSnackBar();
      scaffold.showSnackBar(SnackBar(
        content: const Text('Post unhidden'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            try {
              await actions.hide(fullname);
              await onUndo?.call();
            } catch (_) {
              // Undo failed silently; the optimistic revert in the
              // notifier keeps UI consistent with server state.
            }
          },
        ),
        duration: const Duration(seconds: 4),
      ));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unhide failed: $e'),
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }
}

Future<void> handleSave(
  PostActionsService actions,
  String fullname,
  BuildContext context, {
  bool wasSaved = false,
}) async {
  try {
    await actions.toggleSave(fullname);
    if (context.mounted) {
      final message = wasSaved ? 'Removed from saved' : 'Saved';
      final scaffold = ScaffoldMessenger.of(context);
      scaffold.hideCurrentSnackBar();
      scaffold.showSnackBar(SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            try {
              actions.toggleSave(fullname);
            } catch (_) {
              // Undo failed silently; the optimistic revert in the
              // notifier keeps UI consistent with server state.
            }
          },
        ),
        duration: const Duration(seconds: 4),
      ));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: $e'),
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }
}

/// Shows a confirmation dialog and deletes [fullname] on confirm.
///
/// Returns `true` when the delete succeeded, `false` when the user cancelled
/// or the delete failed. Callers can use the result to refresh UI (e.g.
/// invalidate a provider so the deleted item disappears immediately).
Future<bool> handleDelete(
  BuildContext context,
  PostActionsService actions,
  String fullname,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete'),
      content: const Text('This cannot be undone.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text('Delete',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;
  try {
    await actions.delete(fullname);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deleted'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
    return false;
  }
}
