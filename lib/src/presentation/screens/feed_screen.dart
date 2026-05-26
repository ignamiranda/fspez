import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_providers.dart';
import '../../data/feed_providers.dart';
import '../../data/write_providers.dart';
import '../../data/reddit_client_provider.dart';
import '../../data/feed_pagination.dart';
import '../../domain/enums/feed_sort.dart';
import '../utils/interaction_helpers.dart';
import '../widgets/post_list.dart';
import 'post_detail_screen.dart';
import 'search_screen.dart';
import 'subreddit_feed_screen.dart';
import 'user_profile_screen.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  FeedSort _sort = FeedSort.hot;
  bool _showAll = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        final config = _buildConfig();
        ref.read(feedPageProvider(config).notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  FeedPageConfig _buildConfig() {
    if (_showAll) return FeedPageConfig.popularAll(sort: _sort);
    final account = ref.read(activeAccountProvider);
    final loggedIn = account != null;
    return loggedIn
        ? FeedPageConfig.home(sort: _sort)
        : const FeedPageConfig.popular();
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(activeAccountProvider);
    final loggedIn = account != null;
    final config = _showAll
        ? FeedPageConfig.popularAll(sort: _sort)
        : loggedIn
            ? FeedPageConfig.home(sort: _sort)
            : const FeedPageConfig.popular();
    final state = ref.watch(feedPageProvider(config));
    final notifier = ref.read(feedPageProvider(config).notifier);
    final voteOverrides = ref.watch(voteProvider);
    final saveOverrides = ref.watch(saveProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _showAll ? 'Popular' : loggedIn ? 'fspez' : 'Popular',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(feedPageProvider(_buildConfig()).notifier).refresh(),
          ),
          IconButton(
            icon: Icon(_showAll ? Icons.home : Icons.whatshot),
            tooltip: _showAll ? 'Home' : 'Popular',
            onPressed: () {
              setState(() => _showAll = !_showAll);
            },
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
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : PostList(
              scrollController: _scrollController,
              posts: state.posts,
              onRefresh: () async => notifier.refresh(),
              voteOverrides: voteOverrides,
              saveOverrides: saveOverrides,
              onPostVote: (fullname, dir) =>
                  handleVote(ref.read(voteProvider.notifier), fullname, dir),
               onPostSave: (fullname) =>
                  handleSave(ref.read(saveProvider.notifier), fullname, context),
              onPostDelete: account != null
                  ? (post) {
                      handleDelete(context, ref.read(redditClientProvider),
                          post.fullname, account.sessionCookie);
                    }
                  : null,
              currentUsername: account?.username,
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
              onAuthorTap: (post) {
                if (post.author != '[deleted]') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => UserProfileScreen(username: post.author),
                    ),
                  );
                }
              },
              footer: state.isLoadingMore
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : null,
            ),
    );
  }
}
