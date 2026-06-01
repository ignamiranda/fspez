import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_providers.dart';
import '../../data/feed_pagination.dart';
import '../../data/feed_providers.dart';
import '../../data/comment_providers.dart';
import '../../domain/enums/feed_sort.dart';
import '../../domain/models/subreddit.dart';
import '../utils/infinite_scroll.dart';
import '../utils/format_utils.dart';
import '../utils/reddit_markdown.dart';
import '../widgets/bottom_sheet_menu.dart';
import '../widgets/feed_screen_scaffold.dart';
import '../widgets/subreddit_rules_sheet.dart';
import 'search_screen.dart';
import 'submit_screen.dart';

class SubredditFeedScreen extends ConsumerStatefulWidget {
  final String subredditName;

  const SubredditFeedScreen({super.key, required this.subredditName});

  @override
  ConsumerState<SubredditFeedScreen> createState() =>
      _SubredditFeedScreenState();
}

class _SubredditFeedScreenState extends ConsumerState<SubredditFeedScreen> {
  FeedSort _sort = FeedSort.hot;
  Subreddit? _subInfo;
  bool _isSubscribed = false;
  bool _togglingSub = false;
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSubInfo());
    _scrollController = createInfiniteScrollController(
      () => ref
          .read(feedPageProvider(
                  FeedPageConfig.subreddit(widget.subredditName, sort: _sort))
              .notifier)
          .loadMore(),
    );
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  Future<void> _loadSubInfo() async {
    try {
      final repo = ref.read(subredditRepositoryProvider);
      final cookie = ref.read(activeAccountProvider)?.sessionCookie;
      final sub = await repo.fetch(widget.subredditName, sessionCookie: cookie);
      setState(() {
        _subInfo = sub;
        _isSubscribed = sub.isSubscribed;
      });
    } catch (_) {}
  }

  Future<void> _toggleSubscribe() async {
    setState(() => _togglingSub = true);
    final repo = ref.read(subredditRepositoryProvider);
    final cookie = ref.read(activeAccountProvider)?.sessionCookie;
    try {
      if (_isSubscribed) {
        await repo.unsubscribe(widget.subredditName, sessionCookie: cookie);
      } else {
        await repo.subscribe(widget.subredditName, sessionCookie: cookie);
      }
      setState(() {
        _isSubscribed = !_isSubscribed;
        _togglingSub = false;
      });
    } catch (_) {
      setState(() => _togglingSub = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = FeedPageConfig.subreddit(widget.subredditName, sort: _sort);

    return Scaffold(
      appBar: AppBar(
        title: Text('r/${widget.subredditName}'),
        actions: [
          IconButton(
            tooltip: 'Search in this subreddit',
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SearchScreen(
                  initialSubredditScope: widget.subredditName,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(feedPageProvider(config).notifier).refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () async {
              final sort = await showRadioBottomSheet<FeedSort>(
                context,
                title: 'Sort feed',
                currentValue: _sort,
                values: FeedSort.values,
                labelFn: (s) => s.label,
              );
              if (sort != null && sort != _sort) {
                setState(() => _sort = sort);
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'submit_fab',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SubmitScreen(subreddit: widget.subredditName),
          ),
        ),
        child: const Icon(Icons.edit),
      ),
      body: Column(
        children: [
          if (_subInfo != null)
            _SubredditHeader(
              sub: _subInfo!,
              isSubscribed: _isSubscribed,
              loading: _togglingSub,
              onToggle: _toggleSubscribe,
              onAbout: () => _showAboutSheet(_subInfo!),
              onRules: () => showSubredditRulesSheet(
                context,
                subredditName: widget.subredditName,
              ),
            ),
          Expanded(
            child: FeedScreenScaffold(
              config: config,
              scrollController: _scrollController!,
              onSubredditTapOverride: (post) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => SubredditFeedScreen(
                      subredditName: post.subreddit.name,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutSheet(Subreddit sub) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _SubredditAboutSheet(sub: sub),
    );
  }
}

class _SubredditLetterAvatar extends StatelessWidget {
  final String name;
  final ThemeData theme;

  const _SubredditLetterAvatar({required this.name, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'r',
        style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
      ),
    );
  }
}

class _SubredditHeader extends StatelessWidget {
  final Subreddit sub;
  final bool isSubscribed;
  final bool loading;
  final VoidCallback onToggle;
  final VoidCallback onAbout;
  final VoidCallback onRules;

  const _SubredditHeader({
    required this.sub,
    required this.isSubscribed,
    required this.loading,
    required this.onToggle,
    required this.onAbout,
    required this.onRules,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 40,
              height: 40,
              child: sub.iconUrl != null
                  ? Image.network(
                      sub.iconUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _SubredditLetterAvatar(name: sub.name, theme: theme),
                    )
                  : _SubredditLetterAvatar(name: sub.name, theme: theme),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub.description ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatCount(sub.subscriberCount)} subscribers',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton.outlined(
                    tooltip: 'About this community',
                    onPressed: onAbout,
                    icon: const Icon(Icons.info_outline),
                  ),
                  const SizedBox(width: 4),
                  IconButton.outlined(
                    tooltip: 'Community rules',
                    onPressed: onRules,
                    icon: const Icon(Icons.rule_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: loading ? null : onToggle,
                child: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isSubscribed ? 'Joined' : 'Join'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubredditAboutSheet extends StatelessWidget {
  final Subreddit sub;

  const _SubredditAboutSheet({required this.sub});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              sub.displayName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (_hasText(sub.description)) ...[
              const SizedBox(height: 8),
              Text(
                sub.description!.trim(),
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (sub.isNsfw)
                  _StatusChip(
                    label: 'NSFW',
                    icon: Icons.visibility_off_outlined,
                    color: colorScheme.error,
                  ),
                if (sub.isQuarantined)
                  _StatusChip(
                    label: 'Quarantined',
                    icon: Icons.warning_amber_outlined,
                    color: colorScheme.error,
                  ),
                if (sub.isRestricted)
                  _StatusChip(
                    label: 'Restricted',
                    icon: Icons.lock_outline,
                    color: colorScheme.secondary,
                  ),
                if (sub.isPrivate)
                  _StatusChip(
                    label: 'Private',
                    icon: Icons.lock_outline,
                    color: colorScheme.secondary,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _AboutInfoRow(
              icon: Icons.group_outlined,
              label: 'Members',
              value: formatCount(sub.subscriberCount),
            ),
            if (sub.activeUserCount != null) ...[
              const SizedBox(height: 12),
              _AboutInfoRow(
                icon: Icons.circle_outlined,
                label: 'Online',
                value: formatCount(sub.activeUserCount!),
              ),
            ],
            if (sub.createdAt != null) ...[
              const SizedBox(height: 12),
              _AboutInfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Created',
                value: _formatCreatedDate(sub.createdAt!),
              ),
            ],
            if (_hasText(sub.sidebarDescription)) ...[
              const SizedBox(height: 20),
              Text(
                'Sidebar',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              MarkdownBody(
                data: normalizeRedditMarkdown(sub.sidebarDescription!.trim()),
                styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                  p: theme.textTheme.bodyMedium,
                  a: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                  blockquoteDecoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: colorScheme.outlineVariant,
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

  String _formatCreatedDate(DateTime createdAt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[createdAt.month - 1]} ${createdAt.day}, ${createdAt.year}';
  }
}

class _AboutInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AboutInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Text(label, style: theme.textTheme.bodyMedium),
        const Spacer(),
        Text(
          value.isEmpty ? '0' : value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: color),
      labelStyle: TextStyle(color: color),
      backgroundColor: Colors.transparent,
    );
  }
}
