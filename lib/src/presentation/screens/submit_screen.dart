import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_providers.dart';
import '../../data/write_providers.dart';
import '../widgets/subreddit_rules_sheet.dart';

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

  bool get _hasSubreddit => _subredditController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (widget.subreddit != null) {
      _subredditController.text = widget.subreddit!;
    }
    _subredditController.addListener(() => setState(() {}));
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

    final fields = <String, String>{
      'kind': _isLink ? 'link' : 'self',
      'sr': subreddit,
      'title': title,
      'uh': account.sessionCookie.modhash ?? '',
    };
    if (!_isLink && _textController.text.trim().isNotEmpty) {
      fields['text'] = _textController.text.trim();
    }
    if (_isLink && _urlController.text.trim().isNotEmpty) {
      fields['url'] = _urlController.text.trim();
    }

    final success = await ref.read(submitProvider.notifier).submit(
          fields: fields,
          sessionCookie: account.sessionCookie,
        );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post submitted'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      final state = ref.read(submitProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: ${state.error}')),
      );
    }
  }

  void _showRules() {
    final subreddit = _subredditController.text.trim();
    if (subreddit.isEmpty) return;
    showSubredditRulesSheet(context, subredditName: subreddit);
  }

  @override
  Widget build(BuildContext context) {
    final submitState = ref.watch(submitProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          if (submitState.isSubmitting)
            const Center(
                child: SizedBox(
              width: 20,
              height: 20,
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
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _hasSubreddit ? _showRules : null,
              icon: const Icon(Icons.rule_outlined),
              label: const Text('View community rules'),
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
