import 'package:flutter/material.dart';
import '../../data/save_notifier.dart';
import '../../data/vote_notifier.dart';
import '../../domain/enums/vote_direction.dart';

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
