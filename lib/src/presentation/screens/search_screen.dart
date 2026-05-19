import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers.dart';
import '../../domain/enums/vote_direction.dart';
import '../utils/interaction_helpers.dart';
import '../widgets/feed_loader.dart';
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
  late FeedLoader _feeder;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _feeder = FeedLoader(
      fetchPage: ({after}) {
        final repo = ref.read(feedRepositoryProvider);
        final cookie = ref.read(activeAccountProvider)?.sessionCookie;
        return repo.search(_searchController.text.trim(),
            after: after, sessionCookie: cookie);
      },
    );
    _feeder.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _feeder.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() => _hasSearched = true);
    _feeder.loadInitial();
  }

  @override
  Widget build(BuildContext context) {
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

    if (!_hasSearched) {
      return const Center(
        child: Text('Enter a query to search Reddit'),
      );
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
      emptyMessage: 'No results found.',
      footer: _feeder.isLoadingMore
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          : null,
    );
  }
}
