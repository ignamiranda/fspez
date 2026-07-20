import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/write_providers.dart';

class SubmitVideoTab extends ConsumerWidget {
  const SubmitVideoTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(submitProvider);
    final notifier = ref.read(submitProvider.notifier);
    final selected = state.selectedVideo;

    if (selected == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                final result = await FilePicker.pickFiles(
                  type: FileType.video,
                  allowMultiple: false,
                );
                if (result != null && result.files.isNotEmpty) {
                  notifier.setVideo(result.files.first);
                }
              },
              icon: const Icon(Icons.videocam_outlined),
              label: const Text('Pick Video'),
            ),
            const SizedBox(height: 8),
            Text(
              'Max 1GB, 15 minutes',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    final sizeMb = selected.size / (1024 * 1024);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(Icons.videocam, size: 80, color: Colors.grey),
          const SizedBox(height: 12),
          Text(selected.name, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('${sizeMb.toStringAsFixed(1)} MB',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await FilePicker.pickFiles(
                    type: FileType.video,
                    allowMultiple: false,
                  );
                  if (result != null && result.files.isNotEmpty) {
                    notifier.setVideo(result.files.first);
                  }
                },
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: const Text('Change'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => notifier.clearVideo(),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Remove'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
