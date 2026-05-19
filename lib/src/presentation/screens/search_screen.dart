import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers.dart';
import '../../data/feed_pagination.dart';
import '../../domain/enums/vote_direction.dart';
import '../utils/interaction_helpers.dart';
import '../widgets/post_list.dart';
import 'post_detail_screen.dart';
import 'subreddit_feed_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  bool _hasSearched = false;
  String _lastQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _hasSearched = true;
      _lastQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = FeedPageConfig.search(_lastQuery);
    final state = _hasSearched ? ref.watch(feedPageProvider(config)) : null;
    final notifier = _hasSearched
        ? ref.read(feedPageProvider(config).notifier)
        : null;
    final voteOverrides = ref.watch(voteProvider);
    final saveOverrides = ref.watch(saveProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search Reddit...',
            border: InputBorder.none,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _search,
          ),
        ],
      ),
      body: _buildBody(state, notifier, voteOverrides, saveOverrides),
    );
  }

  Widget _buildBody(
    FeedPageState? state,
    FeedPageNotifier? notifier,
    Map<String, VoteDirection> voteOverrides,
    Map<String, bool> saveOverrides,
  ) {
    if (!_hasSearched) {
      return const Center(
        child: Text('Enter a query to search Reddit'),
      );
    }

    if (state == null || state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return PostList(
      scrollController: notifier!.scrollController,
      posts: state.posts,
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
      emptyMessage: 'No results found.',
      footer: state.isLoadingMore
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          : null,
    );
  }
}
