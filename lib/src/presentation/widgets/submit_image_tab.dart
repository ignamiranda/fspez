import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/write_providers.dart';

class SubmitImageTab extends ConsumerWidget {
  const SubmitImageTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(submitProvider);
    final notifier = ref.read(submitProvider.notifier);
    final selected = state.selectedImage;

    if (selected == null) {
      return Center(
        child: OutlinedButton.icon(
          onPressed: () async {
            final result = await FilePicker.pickFiles(
              type: FileType.image,
              allowMultiple: false,
            );
            if (result != null && result.files.isNotEmpty) {
              notifier.setImage(result.files.first);
            }
          },
          icon: const Icon(Icons.image_outlined),
          label: const Text('Pick Image'),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (selected.path != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(selected.path!),
                height: 200,
                fit: BoxFit.contain,
              ),
            ),
          const SizedBox(height: 8),
          Text(selected.name, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await FilePicker.pickFiles(
                    type: FileType.image,
                    allowMultiple: false,
                  );
                  if (result != null && result.files.isNotEmpty) {
                    notifier.setImage(result.files.first);
                  }
                },
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: const Text('Change'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => notifier.clearImage(),
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
