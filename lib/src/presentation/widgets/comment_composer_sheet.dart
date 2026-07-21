import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/comment_providers.dart';
import '../../data/auth_providers.dart';
import '../utils/error_messages.dart';
import 'reddit_body.dart';
import 'shared/confirm_dialog.dart';

Future<bool?> showCommentComposerSheet(
  BuildContext context, {
  required String thingId,
  String? parentAuthor,
  String? parentBody,
  String initialText = '',
  bool isEdit = false,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _CommentComposerSheetContent(
      thingId: thingId,
      parentAuthor: parentAuthor,
      parentBody: parentBody,
      initialText: initialText,
      isEdit: isEdit,
    ),
  );
}

class _CommentComposerSheetContent extends ConsumerStatefulWidget {
  final String thingId;
  final String? parentAuthor;
  final String? parentBody;
  final String initialText;
  final bool isEdit;

  const _CommentComposerSheetContent({
    required this.thingId,
    this.parentAuthor,
    this.parentBody,
    required this.initialText,
    required this.isEdit,
  });

  @override
  ConsumerState<_CommentComposerSheetContent> createState() =>
      _CommentComposerSheetContentState();
}

class _CommentComposerSheetContentState
    extends ConsumerState<_CommentComposerSheetContent> {
  late final TextEditingController _controller;
  bool _isSending = false;
  bool _showPreview = false;
  String? _error;
  bool _textChanged = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!_textChanged && _controller.text.isNotEmpty) {
      setState(() => _textChanged = true);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final account = ref.read(activeAccountProvider);
    if (account == null) return;

    setState(() {
      _isSending = true;
      _error = null;
    });

    try {
      final repo = ref.read(commentRepositoryProvider);
      if (widget.isEdit) {
        await repo.edit(
          thingId: widget.thingId,
          text: text,
          sessionCookie: account.sessionCookie,
        );
      } else {
        await repo.reply(
          thingId: widget.thingId,
          text: text,
          sessionCookie: account.sessionCookie,
        );
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
          _error = userFriendlyErrorMessage(e);
        });
      }
    }
  }

  void _insertMarkdown(String before, String after, {String? placeholder}) {
    final text = _controller.text;
    final selection = _controller.selection;
    final start = selection.start;
    final end = selection.end;
    String newText;
    int cursorOffset;

    if (start != end) {
      final selected = text.substring(start, end);
      newText =
          '${text.substring(0, start)}$before$selected$after${text.substring(end)}';
      cursorOffset = start + before.length + selected.length + after.length;
    } else if (placeholder != null) {
      newText =
          '${text.substring(0, start)}$before$placeholder$after${text.substring(start)}';
      cursorOffset = start + before.length;
    } else {
      newText =
          '${text.substring(0, start)}$before$after${text.substring(start)}';
      cursorOffset = start + before.length;
    }

    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(offset: cursorOffset);
  }

  void _insertLinePrefix(String prefix) {
    final text = _controller.text;
    final pos = _controller.selection.start;
    final lineStart = text.lastIndexOf('\n', pos - 1) + 1;
    final newText =
        '${text.substring(0, lineStart)}$prefix${text.substring(lineStart)}';
    _controller.text = newText;
    _controller.selection =
        TextSelection.collapsed(offset: pos + prefix.length);
  }

  Future<bool?> _confirmDiscard() {
    return showDiscardDraftDialog(
      context,
      content: 'You have unsent text. Discard it?',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: !_textChanged,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final discard = await _confirmDiscard();
        if (discard == true && context.mounted) {
          Navigator.of(context).pop(null);
        }
      },
      child: Padding(
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
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (widget.parentAuthor != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.reply,
                            size: 14, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Replying to u/${widget.parentAuthor}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (widget.parentBody != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.parentBody!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ToolbarButton(
                    icon: Icons.format_bold,
                    tooltip: 'Bold',
                    onPressed: () =>
                        _insertMarkdown('**', '**', placeholder: 'bold'),
                  ),
                  _ToolbarButton(
                    icon: Icons.format_italic,
                    tooltip: 'Italic',
                    onPressed: () =>
                        _insertMarkdown('*', '*', placeholder: 'italic'),
                  ),
                  _ToolbarButton(
                    icon: Icons.strikethrough_s,
                    tooltip: 'Strikethrough',
                    onPressed: () => _insertMarkdown('~~', '~~',
                        placeholder: 'strikethrough'),
                  ),
                  _ToolbarButton(
                    icon: Icons.link,
                    tooltip: 'Link',
                    onPressed: () =>
                        _insertMarkdown('[', '](url)', placeholder: 'text'),
                  ),
                  _ToolbarButton(
                    icon: Icons.format_quote,
                    tooltip: 'Quote',
                    onPressed: () => _insertLinePrefix('> '),
                  ),
                  _ToolbarButton(
                    icon: Icons.code,
                    tooltip: 'Code',
                    onPressed: () =>
                        _insertMarkdown('`', '`', placeholder: 'code'),
                  ),
                  _ToolbarButton(
                    icon: Icons.format_list_bulleted,
                    tooltip: 'Bullet list',
                    onPressed: () => _insertLinePrefix('- '),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 24,
                    color: theme.dividerColor,
                  ),
                  const SizedBox(width: 8),
                  _ToolbarButton(
                    icon: _showPreview ? Icons.edit : Icons.visibility,
                    tooltip: _showPreview ? 'Edit' : 'Preview',
                    onPressed: () =>
                        setState(() => _showPreview = !_showPreview),
                    selected: _showPreview,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (_showPreview)
              Container(
                constraints:
                    const BoxConstraints(minHeight: 120, maxHeight: 300),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  child: _controller.text.trim().isEmpty
                      ? Text(
                          'Nothing to preview',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        )
                      : RedditBody(_controller.text),
                ),
              )
            else
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                  hintText: widget.isEdit
                      ? 'Edit your comment...'
                      : widget.parentAuthor != null
                          ? 'Write a reply...'
                          : 'Add a comment...',
                ),
                maxLines: 6,
                minLines: 3,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
              ),
            const SizedBox(height: 8),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_isSending)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  FilledButton.icon(
                    onPressed: _controller.text.trim().isEmpty ? null : _send,
                    icon: const Icon(Icons.send, size: 18),
                    label: Text(widget.isEdit ? 'Save' : 'Send'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool selected;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
        style: selected
            ? IconButton.styleFrom(
                backgroundColor: theme.colorScheme.primaryContainer,
              )
            : null,
      ),
    );
  }
}
