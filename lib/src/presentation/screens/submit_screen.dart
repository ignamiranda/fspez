import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_providers.dart';
import '../../data/write_providers.dart';
import '../../domain/models/flair_option.dart';
import '../widgets/flair_picker_sheet.dart';
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
    _subredditController.addListener(_onSubredditChanged);
  }

  void _onSubredditChanged() {
    setState(() {});
    ref
        .read(submitProvider.notifier)
        .onSubredditChanged(_subredditController.text);
  }

  @override
  void dispose() {
    _subredditController.removeListener(_onSubredditChanged);
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

    final success = await ref
        .read(submitProvider.notifier)
        .submit(fields: fields, sessionCookie: account.sessionCookie);

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

  Future<void> _showFlairPicker() async {
    final notifier = ref.read(submitProvider.notifier);
    final state = ref.read(submitProvider);
    if (state.flairOptions.isEmpty) return;

    final picked = await showFlairPickerSheet(
      context,
      options: state.flairOptions,
      currentSelection: state.selectedFlair,
    );

    if (!mounted) return;
    if (picked != state.selectedFlair) {
      notifier.selectFlair(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitState = ref.watch(submitProvider);
    final canSubmit = submitState.canSubmit;

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
              ),
            )
          else
            TextButton(
              onPressed: canSubmit ? _submit : null,
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
          // Flair section — visible when flair options exist for the target subreddit.
          if (submitState.flairOptions.isNotEmpty) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: _showFlairPicker,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Flair',
                  border: const OutlineInputBorder(),
                  suffixIcon: submitState.isFetchingFlairs
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const Icon(Icons.arrow_drop_down),
                ),
                child: submitState.selectedFlair != null
                    ? _FlairChip(flair: submitState.selectedFlair!)
                    : Text(
                        submitState.isFetchingFlairs
                            ? 'Loading…'
                            : 'Select a flair',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
              ),
            ),
            if (submitState.isFlairRequired &&
                submitState.selectedFlair == null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 12),
                child: Text(
                  'This community requires flair',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ),
          ],
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

/// Small pill showing the selected flair text with its colors.
class _FlairChip extends StatelessWidget {
  final FlairOption flair;

  const _FlairChip({required this.flair});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = flair.backgroundColor != null
        ? Color(flair.backgroundColor!)
        : theme.colorScheme.surfaceContainerHighest;
    final fg = _resolveForeground(bg);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        flair.displayText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelLarge?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
    );
  }

  Color _resolveForeground(Color background) {
    if (flair.textColor != null) {
      return Color(flair.textColor!);
    }
    final luminance = _relativeLuminance(background);
    return luminance > 0.179 ? Colors.black87 : Colors.white;
  }

  static double _relativeLuminance(Color c) {
    final r = _linearize(c.r);
    final g = _linearize(c.g);
    final b = _linearize(c.b);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double _linearize(double v) {
    return (v <= 0.04045) ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) as double;
  }
}
