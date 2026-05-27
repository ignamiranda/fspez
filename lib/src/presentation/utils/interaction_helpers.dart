import 'package:flutter/material.dart';
import '../../data/save_notifier.dart';
import '../../data/vote_notifier.dart';
import '../../data/delete_notifier.dart';
import '../../domain/enums/vote_direction.dart';
import '../../domain/models/session_cookie.dart';

void handleVote(VoteNotifier notifier, String fullname, VoteDirection direction) {
  notifier.toggle(fullname, direction);
}

Future<void> handleSave(SaveNotifier notifier, String fullname, BuildContext context) async {
  try {
    await notifier.toggle(fullname);
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

Future<void> handleDelete(
  BuildContext context,
  DeleteNotifier notifier,
  String fullname,
  SessionCookie sessionCookie,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete'),
      content: const Text('This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text('Delete', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  try {
    await notifier.delete(fullname, sessionCookie);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deleted'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }
}
