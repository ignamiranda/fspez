import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers.dart';
import '../../domain/enums/feed_sort.dart';
import '../../domain/enums/vote_direction.dart';
import '../../domain/models/subreddit.dart';
import '../../domain/models/post.dart';
import '../utils/interaction_helpers.dart';
import '../widgets/post_list.dart';
import 'post_detail_screen.dart';

class SubredditFeedScreen extends ConsumerStatefulWidget {
  final String subredditName;

  const SubredditFeedScreen({super.key, required this.subredditName});

  @override
  ConsumerState<SubredditFeedScreen> createState() =>
      _SubredditFeedScreenState();
}

class _SubredditFeedScreenState extends ConsumerState<SubredditFeedScreen> {
  FeedSort _sort = FeedSort.hot;
  final _scrollController = ScrollController();

  List<Post> _posts = [];
  String? _after;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  Subreddit? _subInfo;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitial();
      _loadSubInfo();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _isLoadingMore = false;
      _posts = [];
      _after = null;
      _hasMore = true;
    });
    try {
      final repo = ref.read(feedRepositoryProvider);
      final cookie = ref.read(activeAccountProvider)?.sessionCookie;
      final feed = await repo.fetchSubreddit(widget.subredditName,
          sort: _sort, sessionCookie: cookie);
      setState(() {
        _posts = feed.posts;
        _after = feed.after;
        _hasMore = feed.hasMorePages;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final repo = ref.read(feedRepositoryProvider);
      final cookie = ref.read(activeAccountProvider)?.sessionCookie;
      final feed = await repo.fetchSubreddit(widget.subredditName,
          sort: _sort, after: _after, sessionCookie: cookie);
      setState(() {
        _posts.addAll(feed.posts);
        _after = feed.after;
        _hasMore = feed.hasMorePages;
        _isLoadingMore = false;
      });
    } catch (_) {
      setState(() => _isLoadingMore = false);
    }
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
            onPressed: () {
              _loadInitial();
              _loadSubInfo();
            },
          ),
          PopupMenuButton<FeedSort>(
            icon: const Icon(Icons.sort),
            onSelected: (sort) {
              setState(() => _sort = sort);
              _loadInitial();
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
      body: _buildBody(voteOverrides, saveOverrides),
    );
  }

  Widget _buildBody(
    Map<String, VoteDirection> voteOverrides,
    Map<String, bool> saveOverrides,
  ) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        if (_subInfo != null)
          _SubredditHeader(sub: _subInfo!, ref: ref),
        Expanded(
          child: PostList(
            scrollController: _scrollController,
            posts: _posts,
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
            footer: _isLoadingMore
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
          if (sub.iconUrl != null)
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(sub.iconUrl!),
              onBackgroundImageError: (_, __) {},
            )
          else
            CircleAvatar(
              radius: 20,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                sub.name.isNotEmpty ? sub.name[0].toUpperCase() : 'r',
                style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
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
                  '${_formatCount(sub.subscriberCount)} subscribers',
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

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}
