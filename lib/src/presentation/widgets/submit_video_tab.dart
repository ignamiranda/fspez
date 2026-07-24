import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/write_providers.dart';
import 'shared/submit_file_tab.dart';

class SubmitVideoTab extends ConsumerWidget {
  const SubmitVideoTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mediaPickerProvider);
    final notifier = ref.read(mediaPickerProvider.notifier);

    return SubmitFileTab(
      fileType: FileType.video,
      icon: Icons.videocam_outlined,
      pickLabel: 'Pick Video',
      constraintLabel: 'Max 1GB, 15 minutes',
      selectedFile: state.selectedVideo,
      onPick: (file) => notifier.setVideo(file),
      onClear: () => notifier.clearVideo(),
      showSize: true,
      previewBuilder: (file) => const Column(
        children: [
          Icon(Icons.videocam, size: 80, color: Colors.grey),
          SizedBox(height: 12),
        ],
      ),
    );
  }
}
