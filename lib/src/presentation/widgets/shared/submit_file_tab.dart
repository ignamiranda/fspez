import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class SubmitFileTab extends StatelessWidget {
  final FileType fileType;
  final IconData icon;
  final String pickLabel;
  final String constraintLabel;
  final PlatformFile? selectedFile;
  final ValueChanged<PlatformFile> onPick;
  final VoidCallback onClear;
  final Widget Function(PlatformFile)? previewBuilder;
  final bool showSize;

  const SubmitFileTab({
    super.key,
    required this.fileType,
    required this.icon,
    required this.pickLabel,
    required this.constraintLabel,
    required this.selectedFile,
    required this.onPick,
    required this.onClear,
    this.previewBuilder,
    this.showSize = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (selectedFile == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                final result = await FilePicker.pickFiles(
                  type: fileType,
                  allowMultiple: false,
                );
                if (result != null && result.files.isNotEmpty) {
                  onPick(result.files.first);
                }
              },
              icon: Icon(icon),
              label: Text(pickLabel),
            ),
            const SizedBox(height: 8),
            Text(
              constraintLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (previewBuilder != null)
            previewBuilder!(selectedFile!)
          else if (selectedFile!.path != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(selectedFile!.path!),
                height: 200,
                fit: BoxFit.contain,
              ),
            )
          else ...[
            Icon(icon, size: 80, color: Colors.grey),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          Text(selectedFile!.name, style: theme.textTheme.bodySmall),
          if (showSize) ...[
            const SizedBox(height: 4),
            Text(
              '${(selectedFile!.size / (1024 * 1024)).toStringAsFixed(1)} MB',
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await FilePicker.pickFiles(
                    type: fileType,
                    allowMultiple: false,
                  );
                  if (result != null && result.files.isNotEmpty) {
                    onPick(result.files.first);
                  }
                },
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: const Text('Change'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: onClear,
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
