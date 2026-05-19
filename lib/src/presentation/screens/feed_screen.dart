import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers.dart';
import '../../domain/enums/feed_sort.dart';
import '../../domain/enums/vote_direction.dart';
import '../../domain/models/account.dart';
import '../utils/interaction_helpers.dart';
import '../widgets/feed_loader.dart';
import '../widgets/post_list.dart';
import 'post_detail_screen.dart';
import 'search_screen.dart';
import 'subreddit_feed_screen.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  FeedSort _sort = FeedSort.hot;
  late FeedLoader _feeder;
  Account? _account;

  @override
  void initState() {
    super.initState();
    _initFeeder();
    WidgetsBinding.instance.addPostFrameCallback((_) => _feeder.loadInitial());
  }

  void _initFeeder() {
    _feeder = FeedLoader(
      fetchPage: ({after}) {
        final repo = ref.read(feedRepositoryProvider);
        final cookie = ref.read(activeAccountProvider)?.sessionCookie;
        return _account != null
            ? repo.fetchHome(sort: _sort, after: after, sessionCookie: cookie)
            : repo.fetchPopular(after: after, sessionCookie: cookie);
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
  }

  @override
  Widget build(BuildContext context) {
    final voteOverrides = ref.watch(voteProvider);
    final saveOverrides = ref.watch(saveProvider);
    final account = ref.watch(activeAccountProvider);
    final loggedIn = account != null;

    if (account != _account) {
      _account = account;
      _reload();
    }

    final title = loggedIn ? 'fspez' : 'Popular';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
          if (loggedIn)
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
      body: _buildBody(voteOverrides, saveOverrides, loggedIn),
    );
  }

  Widget _buildBody(
    Map<String, VoteDirection> voteOverrides,
    Map<String, bool> saveOverrides,
    bool loggedIn,
  ) {
    if (_feeder.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return PostList(
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
      footer: _feeder.isLoadingMore
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          : null,
    );
  }
}
