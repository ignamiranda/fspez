import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/comment_providers.dart';
import '../../domain/models/subreddit_rule.dart';
import '../utils/reddit_markdown.dart';

final _lastFetchTimes = <String, DateTime>{};
const _rateLimit = Duration(seconds: 30);

Future<void> showSubredditRulesSheet(
  BuildContext context, {
  required String subredditName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (_) => _SubredditRulesSheet(subredditName: subredditName),
  );
}

class _SubredditRulesSheet extends ConsumerStatefulWidget {
  final String subredditName;

  const _SubredditRulesSheet({required this.subredditName});

  @override
  ConsumerState<_SubredditRulesSheet> createState() =>
      _SubredditRulesSheetState();
}

class _SubredditRulesSheetState extends ConsumerState<_SubredditRulesSheet> {
  bool _refreshed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_refreshed) {
      _refreshed = true;
      _maybeRefresh();
    }
  }

  void _maybeRefresh() {
    final last = _lastFetchTimes[widget.subredditName];
    final now = DateTime.now();
    if (last == null || now.difference(last) > _rateLimit) {
      _lastFetchTimes[widget.subredditName] = now;
      ref.invalidate(subredditRulesProvider(widget.subredditName));
    }
  }

  @override
  Widget build(BuildContext context) {
    final rules = ref.watch(subredditRulesProvider(widget.subredditName));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return SafeArea(
          top: false,
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: _RulesHeader(
                    subredditName: widget.subredditName,
                  ),
                ),
              ),
              rules.when(
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _RulesMessage(
                      icon: Icons.error_outline,
                      title: 'Could not load rules',
                      body: error.toString(),
                    ),
                  ),
                ),
                data: (rules) => rules.isEmpty
                    ? const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: _RulesMessage(
                            icon: Icons.rule_folder_outlined,
                            title: 'No rules listed',
                            body: 'This community has not published rules.',
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          18,
                          20,
                          24 + MediaQuery.paddingOf(context).bottom,
                        ),
                        sliver: _RulesList(rules: rules),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RulesHeader extends StatelessWidget {
  final String subredditName;

  const _RulesHeader({required this.subredditName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.gavel_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community rules',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'r/$subredditName',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RulesList extends StatelessWidget {
  final List<SubredditRule> rules;

  const _RulesList({required this.rules});

  @override
  Widget build(BuildContext context) {
    return SliverList.separated(
      itemCount: rules.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        return _RuleCard(number: index + 1, rule: rules[index]);
      },
    );
  }
}

class _RuleCard extends StatelessWidget {
  final int number;
  final SubredditRule rule;

  const _RuleCard({required this.number, required this.rule});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final description = rule.description.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RuleNumber(number: number),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rule.shortName.isEmpty
                              ? 'Rule $number'
                              : rule.shortName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _KindBadge(kind: rule.kind),
                      ],
                    ),
                  ),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 14),
                Divider(color: colorScheme.outlineVariant, height: 1),
                const SizedBox(height: 14),
                MarkdownBody(
                  data: normalizeRedditMarkdown(description),
                  styleSheet: _markdownStyle(theme),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RuleNumber extends StatelessWidget {
  final int number;

  const _RuleNumber({required this.number});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(
        '$number',
        style: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _KindBadge extends StatelessWidget {
  final String kind;

  const _KindBadge({required this.kind});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          _kindLabel(kind),
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String _kindLabel(String kind) {
    return switch (kind) {
      'link' => 'Posts',
      'comment' => 'Comments',
      _ => 'Posts and comments',
    };
  }
}

class _RulesMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _RulesMessage({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: colorScheme.primary),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

MarkdownStyleSheet _markdownStyle(ThemeData theme) {
  final colorScheme = theme.colorScheme;
  return MarkdownStyleSheet.fromTheme(theme).copyWith(
    p: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
    a: TextStyle(
      color: colorScheme.primary,
      decoration: TextDecoration.underline,
    ),
    blockquoteDecoration: BoxDecoration(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.48),
      border: Border(
        left: BorderSide(
          color: colorScheme.primary,
          width: 4,
        ),
      ),
    ),
    code: theme.textTheme.bodyMedium?.copyWith(
      backgroundColor: colorScheme.surfaceContainerHighest,
      fontFamily: 'monospace',
    ),
    codeblockDecoration: BoxDecoration(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
    ),
  );
}
