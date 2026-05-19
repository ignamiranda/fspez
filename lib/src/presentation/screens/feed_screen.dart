import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers.dart';
import '../../domain/enums/feed_sort.dart';
import '../../domain/enums/vote_direction.dart';
import '../../domain/models/account.dart';
import '../../domain/models/post.dart';
import '../utils/interaction_helpers.dart';
import '../widgets/post_list.dart';
import 'post_detail_screen.dart';
import 'subreddit_feed_screen.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  FeedSort _sort = FeedSort.hot;
  final _scrollController = ScrollController();

  List<Post> _posts = [];
  String? _after;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  Account? _account;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
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
      final cookie = _account?.sessionCookie;
      final feed = _account != null
          ? await repo.fetchHome(sort: _sort, sessionCookie: cookie)
          : await repo.fetchPopular(sessionCookie: cookie);
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
      final cookie = _account?.sessionCookie;
      final feed = _account != null
          ? await repo.fetchHome(sort: _sort, after: _after, sessionCookie: cookie)
          : await repo.fetchPopular(after: _after, sessionCookie: cookie);
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

  @override
  Widget build(BuildContext context) {
    final voteOverrides = ref.watch(voteProvider);
    final saveOverrides = ref.watch(saveProvider);
    final account = ref.watch(activeAccountProvider);
    final loggedIn = account != null;

    if (account != _account) {
      _account = account;
      _loadInitial();
    }

    final title = loggedIn ? 'fspez' : 'Popular';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitial,
          ),
          if (loggedIn)
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
      body: _buildBody(voteOverrides, saveOverrides, loggedIn),
    );
  }

  Widget _buildBody(
    Map<String, VoteDirection> voteOverrides,
    Map<String, bool> saveOverrides,
    bool loggedIn,
  ) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return PostList(
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
      onSubredditTap: (post) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SubredditFeedScreen(
            subredditName: post.subreddit.name,
          ),
        ),
      ),
      emptyMessage: loggedIn
          ? 'No posts yet.'
          : 'No posts yet. Log in to see your home feed.',
      footer: _isLoadingMore
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          : null,
    );
  }
}
