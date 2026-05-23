import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers.dart';
import '../../data/feed_pagination.dart';
import '../../domain/enums/feed_sort.dart';
import '../utils/interaction_helpers.dart';
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

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(activeAccountProvider);
    final loggedIn = account != null;
    final config = loggedIn
        ? FeedPageConfig.home(sort: _sort)
        : const FeedPageConfig.popular();
    final state = ref.watch(feedPageProvider(config));
    final notifier = ref.read(feedPageProvider(config).notifier);
    final voteOverrides = ref.watch(voteProvider);
    final saveOverrides = ref.watch(saveProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(loggedIn ? 'fspez' : 'Popular'),
        actions: [
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
              scrollController: notifier.scrollController,
              posts: state.posts,
              onRefresh: () async => notifier.refresh(),
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
