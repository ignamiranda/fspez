import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers.dart';
import '../../domain/enums/vote_direction.dart';
import '../utils/interaction_helpers.dart';
import '../widgets/feed_loader.dart';
import '../widgets/post_list.dart';
import 'post_detail_screen.dart';
import 'subreddit_feed_screen.dart';

class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  late FeedLoader _feeder;

  @override
  void initState() {
    super.initState();
    _feeder = FeedLoader(
      fetchPage: ({after}) {
        final account = ref.read(activeAccountProvider)!;
        final repo = ref.read(feedRepositoryProvider);
        return repo.fetchSaved(account.username,
            after: after, sessionCookie: account.sessionCookie);
      },
    );
    _feeder.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _feeder.loadInitial());
  }

  @override
  void dispose() {
    _feeder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voteOverrides = ref.watch(voteProvider);
    final saveOverrides = ref.watch(saveProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _feeder.loadInitial,
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
      emptyMessage: 'No saved posts yet.',
      footer: _feeder.isLoadingMore
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          : null,
    );
  }
}
