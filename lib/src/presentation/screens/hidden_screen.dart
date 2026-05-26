import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_providers.dart';
import '../../data/feed_providers.dart';
import '../../data/write_providers.dart';
import '../../data/feed_pagination.dart';
import '../../data/reddit_client_provider.dart';
import '../utils/interaction_helpers.dart';
import '../widgets/post_list.dart';
import 'post_detail_screen.dart';
import 'subreddit_feed_screen.dart';
import 'user_profile_screen.dart';

class HiddenScreen extends ConsumerStatefulWidget {
  const HiddenScreen({super.key});

  @override
  ConsumerState<HiddenScreen> createState() => _HiddenScreenState();
}

class _HiddenScreenState extends ConsumerState<HiddenScreen> {
  static const _config = FeedPageConfig.hidden();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        ref.read(feedPageProvider(_config).notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feedPageProvider(_config));
    final notifier = ref.read(feedPageProvider(_config).notifier);
    final voteOverrides = ref.watch(voteProvider);
    final saveOverrides = ref.watch(saveProvider);
    final hidden = ref.watch(hideProvider);
    final account = ref.watch(activeAccountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hidden'),
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
              hiddenFullnames: hidden,
              onPostHide: (post) =>
                  ref.read(hideProvider.notifier).toggle(post.fullname),
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
              emptyMessage: 'No hidden posts.',
            ),
    );
  }
}
