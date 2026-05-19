import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers.dart';
import '../../domain/enums/feed_sort.dart';
import '../../domain/enums/vote_direction.dart';
import '../../domain/models/subreddit.dart';
import '../utils/interaction_helpers.dart';
import '../utils/format_utils.dart';
import '../widgets/feed_loader.dart';
import '../widgets/post_list.dart';
import 'post_detail_screen.dart';
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
  late FeedLoader _feeder;
  Subreddit? _subInfo;

  @override
  void initState() {
    super.initState();
    _initFeeder();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _feeder.loadInitial();
      _loadSubInfo();
    });
  }

  void _initFeeder() {
    _feeder = FeedLoader(
      fetchPage: ({after}) {
        final repo = ref.read(feedRepositoryProvider);
        final cookie = ref.read(activeAccountProvider)?.sessionCookie;
        return repo.fetchSubreddit(widget.subredditName,
            sort: _sort, after: after, sessionCookie: cookie);
      },
    );
    _feeder.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _feeder.dispose();
    super.dispose();
  }

  void _reload() {
    _feeder.dispose();
    _initFeeder();
    _feeder.loadInitial();
    _loadSubInfo();
  }

  Future<void> _loadSubInfo() async {
    try {
      final repo = ref.read(subredditRepositoryProvider);
      final cookie = ref.read(activeAccountProvider)?.sessionCookie;
      final sub = await repo.fetch(widget.subredditName,
          sessionCookie: cookie);
      setState(() => _subInfo = sub);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final voteOverrides = ref.watch(voteProvider);
    final saveOverrides = ref.watch(saveProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('r/${widget.subredditName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
          PopupMenuButton<FeedSort>(
            icon: const Icon(Icons.sort),
            onSelected: (sort) {
              setState(() => _sort = sort);
              _reload();
            },
            itemBuilder: (_) => FeedSort.values.map((sort) {
              return PopupMenuItem(
                value: sort,
                child: Text(sort.name),
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
      body: _buildBody(voteOverrides, saveOverrides),
    );
  }

  Widget _buildBody(
    Map<String, VoteDirection> voteOverrides,
    Map<String, bool> saveOverrides,
  ) {
    if (_feeder.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        if (_subInfo != null)
          _SubredditHeader(sub: _subInfo!, ref: ref),
        Expanded(
          child: PostList(
            scrollController: _feeder.scrollController,
            posts: _feeder.posts,
            voteOverrides: voteOverrides,
            saveOverrides: saveOverrides,
            onPostVote: (fullname, dir) =>
                handleVote(ref.read(voteProvider.notifier), fullname, dir),
            onPostSave: (fullname) =>
                handleSave(ref.read(saveProvider.notifier), fullname, context),
            onPostTap: (post) => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PostDetailScreen(post: post),
              ),
            ),
            onSubredditTap: (post) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => SubredditFeedScreen(
                    subredditName: post.subreddit.name,
                  ),
                ),
              );
            },
            footer: _feeder.isLoadingMore
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : null,
          ),
        ),
      ],
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
  final WidgetRef ref;

  const _SubredditHeader({required this.sub, required this.ref});

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
            onPressed: () {
              final action = sub.isSubscribed ? 'unsubscribe' : 'subscribe';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(action == 'subscribe'
                      ? 'Subscribed to r/${sub.name}'
                      : 'Unsubscribed from r/${sub.name}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Text(sub.isSubscribed ? 'Joined' : 'Join'),
          ),
        ],
      ),
    );
  }
}
