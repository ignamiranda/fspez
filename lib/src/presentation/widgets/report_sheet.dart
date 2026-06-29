import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_providers.dart';
import '../../data/comment_providers.dart';
import '../../data/reddit_client_provider.dart';
import '../../domain/models/subreddit_rule.dart';

class _ReportCategory {
  final String id;
  final String label;
  final bool isSubredditRule;

  const _ReportCategory({
    required this.id,
    required this.label,
    this.isSubredditRule = false,
  });
}

final _siteWideCategories = [
  const _ReportCategory(id: 'spam', label: "It's spam"),
  const _ReportCategory(id: 'harassment', label: "It's harassment"),
  const _ReportCategory(id: 'hate', label: "It's hate"),
  const _ReportCategory(id: 'misinformation', label: "It's misinformation"),
  const _ReportCategory(
    id: 'threatening_violence',
    label: "It's threatening violence",
  ),
  const _ReportCategory(
    id: 'sexual_minors',
    label: 'It\'s sexual or suggestive content involving minors',
  ),
  const _ReportCategory(id: 'impersonation', label: "It's impersonation"),
  const _ReportCategory(
    id: 'vote_manipulation',
    label: "It's vote manipulation",
  ),
  const _ReportCategory(id: 'ban_evasion', label: "It's ban evasion"),
  const _ReportCategory(id: 'self_harm', label: 'It\'s self-harm or suicide'),
  const _ReportCategory(
    id: 'identity_hate',
    label: 'It\'s promoting hate based on identity or vulnerability',
  ),
];

Future<void> showReportSheet(
  BuildContext context, {
  required String thingId,
  String? subreddit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) =>
        _ReportSheetContent(thingId: thingId, subreddit: subreddit),
  );
}

class _ReportSheetContent extends ConsumerStatefulWidget {
  final String thingId;
  final String? subreddit;

  const _ReportSheetContent({required this.thingId, this.subreddit});

  @override
  ConsumerState<_ReportSheetContent> createState() =>
      _ReportSheetContentState();
}

class _ReportSheetContentState extends ConsumerState<_ReportSheetContent> {
  int _step = 1;
  bool _isSubmitting = false;
  String? _error;
  String? _selectedRuleId;

  void _submitReport(String reason) async {
    final account = ref.read(activeAccountProvider);
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await ref
          .read(redditClientProvider)
          .reportContent(
            thingId: widget.thingId,
            reason: reason,
            sessionCookie: account?.sessionCookie,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reported')));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = e.toString();
      });
    }
  }

  void _onCategoryTapped(_ReportCategory category) {
    if (category.isSubredditRule) {
      setState(() {
        _step = 2;
        _selectedRuleId = null;
        _error = null;
      });
    } else {
      _submitReport(category.id);
    }
  }

  void _onRuleTapped(SubredditRule rule) {
    final reason = rule.violationReason ?? rule.shortName;
    _submitReport(reason);
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
          _buildHeader(theme),
          const SizedBox(height: 12),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
              ),
            ),
          Flexible(
            child: _step == 1 ? _buildCategoryList(theme) : _buildRulesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        if (_step == 2)
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() {
              _step = 1;
              _error = null;
            }),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
          ),
        if (_step == 2) const SizedBox(width: 8),
        Expanded(
          child: Text(
            _step == 1 ? 'Report' : 'Breaks r/${widget.subreddit}\'s rules',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryList(ThemeData theme) {
    final categories = List<_ReportCategory>.of(_siteWideCategories);
    if (widget.subreddit != null) {
      categories.insert(
        0,
        _ReportCategory(
          id: '__subreddit_rules__',
          label: "Breaks r/${widget.subreddit}'s rules",
          isSubredditRule: true,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: RadioGroup<String>(
            groupValue: _selectedRuleId,
            onChanged: _isSubmitting
                ? (_) {}
                : (value) {
                    if (value != null) {
                      final category =
                          categories.firstWhere((c) => c.id == value);
                      _onCategoryTapped(category);
                    }
                  },
            child: ListView(
              shrinkWrap: true,
              children: categories
                  .map(
                    (category) => RadioListTile<String>(
                      value: category.id,
                      title: Text(category.label),
                      contentPadding: EdgeInsets.zero,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildRulesList() {
    final rules = ref.watch(subredditRulesProvider(widget.subreddit!));

    return rules.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Could not load rules',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.red),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  ref.invalidate(subredditRulesProvider(widget.subreddit!)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (rules) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: RadioGroup<String>(
              groupValue: _selectedRuleId,
              onChanged: _isSubmitting
                  ? (_) {}
                  : (value) {
                      if (value != null) {
                        final rule = rules.firstWhere(
                          (r) => (r.violationReason ?? r.shortName) == value,
                        );
                        _onRuleTapped(rule);
                      }
                    },
              child: ListView(
                shrinkWrap: true,
                children: rules
                    .map(
                      (rule) => RadioListTile<String>(
                        value: rule.violationReason ?? rule.shortName,
                        title: Text(
                          rule.shortName.isEmpty
                              ? '(untitled)'
                              : rule.shortName,
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
