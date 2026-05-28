import 'package:flutter/material.dart';
import '../../data/post_actions_service.dart';
import '../../domain/enums/vote_direction.dart';

void handleVote(
    PostActionsService actions, String fullname, VoteDirection direction) {
  actions.vote(fullname, direction);
}

Future<void> handleSave(
    PostActionsService actions, String fullname, BuildContext context) async {
  try {
    await actions.toggleSave(fullname);
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
  if (confirmed != true) return;
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
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }
}
