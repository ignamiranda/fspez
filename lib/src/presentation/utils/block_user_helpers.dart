import 'package:flutter/material.dart';
import '../../data/post_actions_notifier.dart';

/// Shows a confirmation dialog and blocks [username] on confirm.
Future<void> handleBlockUser({
  required BuildContext context,
  required PostActionsNotifier notifier,
  required String username,
  String? accountId,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Block u/$username?'),
      content: const Text(
        "They won't be able to view your profile or contact you.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(
            'Block',
            style: TextStyle(color: Theme.of(ctx).colorScheme.error),
          ),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  try {
    if (accountId != null) {
      await notifier.blockKnown(username, accountId);
    } else {
      await notifier.blockUser(username);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Blocked u/$username'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              try {
                if (accountId != null) {
                  await notifier.unblockKnown(username, accountId);
                } else {
                  await notifier.unblockUser(username);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Unblocked u/$username'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Unblock failed')),
                  );
                }
              }
            },
          ),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Block failed: $e'),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}

/// Shows a confirmation dialog and unblocks [username] on confirm.
Future<void> handleUnblockUser({
  required BuildContext context,
  required PostActionsNotifier notifier,
  required String username,
  String? accountId,
}) async {
  try {
    if (accountId != null) {
      await notifier.unblockKnown(username, accountId);
    } else {
      await notifier.unblockUser(username);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unblocked u/$username'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              try {
                if (accountId != null) {
                  await notifier.blockKnown(username, accountId);
                } else {
                  await notifier.blockUser(username);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Blocked u/$username'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Block failed')),
                  );
                }
              }
            },
          ),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unblock failed: $e'),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}
