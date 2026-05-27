import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_providers.dart';
import '../../data/feed_pagination.dart';
import '../../data/feed_providers.dart';
import '../../data/comment_providers.dart';
import '../../domain/enums/feed_sort.dart';
import '../../domain/models/subreddit.dart';
import '../utils/infinite_scroll.dart';
import '../utils/format_utils.dart';
import '../widgets/feed_screen_scaffold.dart';
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
      () => ref.read(feedPageProvider(FeedPageConfig.subreddit(widget.subredditName, sort: _sort)).notifier).loadMore(),
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
      final sub = await repo.fetch(widget.subredditName,
          sessionCookie: cookie);
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
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(feedPageProvider(config).notifier).refresh(),
          ),
          PopupMenuButton<FeedSort>(
            icon: const Icon(Icons.sort),
            onSelected: (sort) {
              setState(() => _sort = sort);
            },
            itemBuilder: (_) => FeedSort.values.map((sort) {
              return PopupMenuItem(
                value: sort,
                child: Text(sort.label),
              );
            }).toList(),
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

  const _SubredditHeader({
    required this.sub,
    required this.isSubscribed,
    required this.loading,
    required this.onToggle,
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
                      errorBuilder: (_, __, ___) => _SubredditLetterAvatar(name: sub.name, theme: theme),
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
    );
  }
}
