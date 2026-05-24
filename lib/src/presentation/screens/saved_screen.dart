import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers.dart';
import '../../data/feed_pagination.dart';
import '../utils/interaction_helpers.dart';
import '../widgets/post_list.dart';
import 'post_detail_screen.dart';
import 'subreddit_feed_screen.dart';
import 'user_profile_screen.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const config = FeedPageConfig.saved();
    final state = ref.watch(feedPageProvider(config));
    final notifier = ref.read(feedPageProvider(config).notifier);
    final voteOverrides = ref.watch(voteProvider);
    final saveOverrides = ref.watch(saveProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: notifier.refresh,
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
      onAuthorTap: (post) {
        if (post.author != '[deleted]') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => UserProfileScreen(username: post.author),
            ),
          );
        }
      },
      emptyMessage: 'No saved posts yet.',
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
