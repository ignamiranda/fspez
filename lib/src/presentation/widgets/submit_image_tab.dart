import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/write_providers.dart';
import 'shared/submit_file_tab.dart';

class SubmitImageTab extends ConsumerWidget {
  const SubmitImageTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mediaPickerProvider);
    final notifier = ref.read(mediaPickerProvider.notifier);

    return SubmitFileTab(
      fileType: FileType.image,
      icon: Icons.image_outlined,
      pickLabel: 'Pick Image',
      constraintLabel: 'Max 20MB per image',
      selectedFile: state.selectedImage,
      onPick: (file) => notifier.setImage(file),
      onClear: () => notifier.clearImage(),
    );
  }
}
