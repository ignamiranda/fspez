import 'package:flutter/material.dart';
import '../../data/post_actions_service.dart';
import '../../domain/enums/vote_direction.dart';
import '../screens/auth_webview_screen.dart';
import 'error_messages.dart';

Future<void> handleVote(
  PostActionsService actions,
  BuildContext context,
  String fullname,
  VoteDirection direction,
) async {
  try {
    await actions.vote(fullname, direction);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vote failed. Try again.'),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }
}

Future<void> handleHide(
  PostActionsService actions,
  String fullname,
  BuildContext context,
) async {
  try {
    await actions.hide(fullname);
    if (context.mounted) {
      final scaffold = ScaffoldMessenger.of(context);
      scaffold.hideCurrentSnackBar();
      scaffold.showSnackBar(SnackBar(
        content: const Text('Post hidden'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            try {
              actions.unhide(fullname);
            } catch (_) {}
          },
        ),
        duration: Duration(seconds: 4),
      ));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hide failed: ${userFriendlyErrorMessage(e)}'),
          duration: Duration(seconds: 8),
        ),
      );
    }
  }
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
          content: Text('Unhide failed: ${userFriendlyErrorMessage(e)}'),
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
          content: Text('Save failed: ${userFriendlyErrorMessage(e)}'),
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
        SnackBar(
            content: Text('Delete failed: ${userFriendlyErrorMessage(e)}')),
      );
    }
    return false;
  }
}

void requireLoginForAction(BuildContext context,
    {String action = 'perform that action'}) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Log in required'),
      content: Text('You need to log in to $action. Log in now?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AuthWebViewScreen()),
            );
          },
          child: const Text('Log in'),
        ),
      ],
    ),
  );
}
