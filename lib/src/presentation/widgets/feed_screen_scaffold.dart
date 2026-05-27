import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_providers.dart';
import '../../data/feed_pagination.dart';
import '../../data/feed_providers.dart';
import '../../data/write_providers.dart';
import '../../domain/models/post.dart';
import '../utils/interaction_helpers.dart';
import 'post_list.dart';
import '../screens/post_detail_screen.dart';
import '../screens/subreddit_feed_screen.dart';
import '../screens/user_profile_screen.dart';

class FeedScreenScaffold extends ConsumerWidget {
  final FeedPageConfig config;
  final ScrollController scrollController;
  final void Function(Post post)? onSubredditTapOverride;
  final String emptyMessage;
  final bool filterHidden;

  const FeedScreenScaffold({
    super.key,
    required this.config,
    required this.scrollController,
    this.onSubredditTapOverride,
    this.emptyMessage = 'No posts yet.',
    this.filterHidden = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(feedPageProvider(config));
    final notifier = ref.read(feedPageProvider(config).notifier);
    final voteOverrides = ref.watch(voteProvider);
    final saveOverrides = ref.watch(saveProvider);
    final hiddenMap = ref.watch(hideProvider);
    final hidden = hiddenMap.entries.where((e) => e.value).map((e) => e.key).toSet();
    final account = ref.watch(activeAccountProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return PostList(
      scrollController: scrollController,
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
              handleDelete(context, ref.read(deleteProvider.notifier),
                  post.fullname, account.sessionCookie);
            }
          : null,
      currentUsername: account?.username,
      hiddenFullnames: filterHidden ? hidden : const {},
      onPostHide: filterHidden
          ? (post) async {
              final notifier = ref.read(hideProvider.notifier);
              try {
                await notifier.toggle(post.fullname);
              } catch (_) {
                return;
              }
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: const Text('Post hidden'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () => notifier.unhide(post.fullname),
                  ),
                  duration: const Duration(seconds: 4),
                ));
            }
          : null,
      onPostUnhide: !filterHidden
          ? (post) async {
              final hideNotifier = ref.read(hideProvider.notifier);
              final feedNotifier = ref.read(feedPageProvider(config).notifier);
              feedNotifier.removePost(post.fullname);
              await hideNotifier.unhide(post.fullname);
            }
          : null,
      onPostTap: (post) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PostDetailScreen(post: post),
        ),
      ),
      onSubredditTap: onSubredditTapOverride ??
          (post) => Navigator.of(context).push(
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
      emptyMessage: emptyMessage,
      footer: state.isLoadingMore
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          : null,
    );
  }
}
