import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/media_picker_notifier.dart';
import '../../data/write_providers.dart';

class SubmitGalleryTab extends ConsumerWidget {
  const SubmitGalleryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mediaPickerProvider);
    final notifier = ref.read(mediaPickerProvider.notifier);

    if (state.galleryFiles.isEmpty) {
      return Center(
        child: OutlinedButton.icon(
          onPressed: () async {
            final result = await FilePicker.pickFiles(
              type: FileType.image,
              allowMultiple: true,
            );
            if (result != null && result.files.isNotEmpty) {
              notifier.setGalleryFiles(result.files);
            }
          },
          icon: const Icon(Icons.collections_outlined),
          label: const Text('Pick Images'),
        ),
      );
    }

    return ReorderableListView(
      padding: const EdgeInsets.all(16),
      // ignore: deprecated_member_use
      onReorder: (oldIndex, newIndex) =>
          notifier.reorderGallery(oldIndex, newIndex),
      footer: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: OutlinedButton.icon(
          onPressed: () async {
            final result = await FilePicker.pickFiles(
              type: FileType.image,
              allowMultiple: true,
            );
            if (result != null && result.files.isNotEmpty) {
              notifier.addGalleryImages(result.files);
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Add more'),
        ),
      ),
      children: [
        for (var i = 0; i < state.galleryFiles.length; i++)
          _buildGalleryItem(context, i, state, notifier),
      ],
    );
  }

  Widget _buildGalleryItem(BuildContext context, int index,
      MediaPickerState state, MediaPickerNotifier notifier) {
    final file = state.galleryFiles[index];
    return Card(
      key: ValueKey(file.path ?? file.name),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            if (file.path != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.file(
                  File(file.path!),
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Caption (optional)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => notifier.updateGalleryCaption(index, value),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => notifier.removeGalleryItem(index),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Remove'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
