import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/write_providers.dart';
import '../../data/auth_providers.dart';

Future<bool?> showEditSheet(
  BuildContext context, {
  required String currentText,
  String? readOnlyTitle,
  required String thingId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _EditSheetContent(
      currentText: currentText,
      readOnlyTitle: readOnlyTitle,
      thingId: thingId,
    ),
  );
}

class _EditSheetContent extends ConsumerStatefulWidget {
  final String currentText;
  final String? readOnlyTitle;
  final String thingId;

  const _EditSheetContent({
    required this.currentText,
    this.readOnlyTitle,
    required this.thingId,
  });

  @override
  ConsumerState<_EditSheetContent> createState() => _EditSheetContentState();
}

class _EditSheetContentState extends ConsumerState<_EditSheetContent> {
  late final TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final account = ref.read(activeAccountProvider);
    if (account == null) return;

    setState(() => _isSaving = true);
    final actions = ref.read(postActionsProvider.notifier);
    final success = await actions.edit(widget.thingId, text);
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Edit failed: ${actions.editError ?? 'Unknown error'}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: bottomInset + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          gesturalHandle(theme),
          const SizedBox(height: 12),
          if (widget.readOnlyTitle != null) ...[
            Text(
              widget.readOnlyTitle!,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(12),
              hintText: 'Edit your content...',
            ),
            maxLines: 8,
            minLines: 3,
            keyboardType: TextInputType.multiline,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed:
                    _isSaving ? null : () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              if (_isSaving)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                FilledButton(
                  onPressed: _save,
                  child: const Text('Save'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget gesturalHandle(ThemeData theme) {
    return Center(
      child: Container(
        width: 32,
        height: 4,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
