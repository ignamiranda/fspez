import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers.dart';
import '../../data/submit_repository.dart';

class SubmitScreen extends ConsumerStatefulWidget {
  final String? subreddit;

  const SubmitScreen({super.key, this.subreddit});

  @override
  ConsumerState<SubmitScreen> createState() => _SubmitScreenState();
}

class _SubmitScreenState extends ConsumerState<SubmitScreen> {
  final _titleController = TextEditingController();
  final _textController = TextEditingController();
  final _urlController = TextEditingController();
  final _subredditController = TextEditingController();
  bool _isLink = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.subreddit != null) {
      _subredditController.text = widget.subreddit!;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    _urlController.dispose();
    _subredditController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final subreddit = _subredditController.text.trim();
    final account = ref.read(activeAccountProvider);
    if (title.isEmpty || subreddit.isEmpty || account == null) return;

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(submitRepositoryProvider);
      await repo.submit(
        kind: _isLink ? SubmitKind.link : SubmitKind.self,
        subreddit: subreddit,
        title: title,
        text: _isLink ? null : _textController.text.trim(),
        url: _isLink ? _urlController.text.trim() : null,
        sessionCookie: account.sessionCookie,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post submitted'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          if (_isSubmitting)
            const Center(child: SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ))
          else
            TextButton(
              onPressed: _submit,
              child: const Text('Submit'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _subredditController,
            decoration: const InputDecoration(
              labelText: 'Subreddit',
              hintText: 'subreddit_name',
              border: OutlineInputBorder(),
              prefixText: 'r/',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Post type:'),
              const SizedBox(width: 12),
              ChoiceChip(
                label: const Text('Text'),
                selected: !_isLink,
                onSelected: (_) => setState(() => _isLink = false),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Link'),
                selected: _isLink,
                onSelected: (_) => setState(() => _isLink = true),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          if (_isLink)
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://...',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            )
          else
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Text (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 8,
            ),
        ],
      ),
    );
  }
}
