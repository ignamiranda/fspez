import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/app_settings.dart';
import '../../data/auth_providers.dart';
import '../../data/feed_pagination.dart';
import '../../data/feed_providers.dart';
import '../../data/write_providers.dart';
import '../../domain/models/post.dart';
import '../utils/block_user_helpers.dart';
import '../utils/interaction_helpers.dart';
import 'feed_media_prefetcher.dart';
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
    final actions = ref.read(postActionsServiceProvider);
    final hidden = hiddenMap.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toSet();
    final account = ref.watch(activeAccountProvider);
    Widget? statusBanner;

    if (state.error != null && state.items.isNotEmpty) {
      statusBanner = Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        color: Colors.orange.shade100,
        child: Row(
          children: [
            const Icon(Icons.error_outline, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                state.error!,
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () => notifier.refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else if (state.isStale && state.items.isNotEmpty) {
      statusBanner = Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        color: Colors.grey.shade100,
        child: const Row(
          children: [
            Icon(Icons.access_time, size: 14),
            SizedBox(width: 4),
            Text('Cached', style: TextStyle(fontSize: 11)),
          ],
        ),
      );
    }

    // Full-screen spinner only when loading with no cached items.
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final postList = PostList(
      scrollController: scrollController,
      posts: state.items,
      onRefresh: () async {
        HapticFeedback.mediumImpact();

        final previousState = state;
        final previousIds = previousState.items.map((p) => p.fullname).toSet();

        String? anchorId;
        if (scrollController.hasClients &&
            scrollController.offset > 0 &&
            previousState.items.isNotEmpty) {
          anchorId = previousState.items[0].fullname;
        }

        try {
          await notifier.refresh();

          final newState = ref.read(feedPageProvider(config));

          if (newState.error != null) {
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text('Could not refresh'),
                    duration: Duration(seconds: 2),
                  ),
                );
            }
            return;
          }

          final newIds = newState.items.map((p) => p.fullname).toSet();
          final addedCount = newIds.difference(previousIds).length;

          if (addedCount > 0) {
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      addedCount == 1
                          ? '1 new post loaded'
                          : '$addedCount new posts loaded',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
            }
          } else if (previousIds.isNotEmpty) {
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text("You're up to date"),
                    duration: Duration(seconds: 2),
                  ),
                );
            }
          }

          if (anchorId != null && scrollController.hasClients) {
            final oldIndex = previousState.items.indexWhere(
              (p) => p.fullname == anchorId,
            );
            final newIndex = newState.items.indexWhere(
              (p) => p.fullname == anchorId,
            );
            if (oldIndex >= 0 && newIndex >= 0) {
              final itemsShift = newIndex - oldIndex;
              if (itemsShift > 0) {
                final estimatedShift = itemsShift * 120.0;
                final newOffset = (scrollController.offset + estimatedShift)
                    .clamp(0.0, scrollController.position.maxScrollExtent);
                scrollController.jumpTo(newOffset);
              }
            }
          }
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  content: Text('Could not refresh'),
                  duration: Duration(seconds: 2),
                ),
              );
          }
        }
      },
      showStickiedIndicator: config.kind == FeedPageKind.subreddit,
      voteOverrides: voteOverrides,
      saveOverrides: saveOverrides,
      onPostVote: actions != null
          ? (fullname, dir) => handleVote(actions, fullname, dir)
          : null,
      onPostSave: actions != null
          ? (fullname) {
              final post = state.items.cast<Post?>().firstWhere(
                (p) => p?.fullname == fullname,
                orElse: () => null,
              );
              final wasSaved = post != null
                  ? (saveOverrides[fullname] ?? post.isSaved)
                  : saveOverrides[fullname] ?? false;
              handleSave(actions, fullname, context, wasSaved: wasSaved);
            }
          : null,
      onPostDelete: actions != null && account != null
          ? (post) async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete'),
                  content: const Text('This cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(
                        'Delete',
                        style: TextStyle(
                          color: Theme.of(ctx).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              );
              if (confirmed != true) return;
              notifier.removeItem((p) => p.fullname == post.fullname);
              var undone = false;
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: const Text('Post deleted'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () {
                        undone = true;
                        notifier.refresh();
                      },
                    ),
                    duration: const Duration(seconds: 4),
                  ),
                );

              await Future<void>.delayed(const Duration(seconds: 4));
              if (undone) return;
              await actions.delete(post.fullname);
            }
          : null,
      currentUsername: account?.username,
      hiddenFullnames: filterHidden ? hidden : const {},
      onPostHide: actions != null && filterHidden
          ? (post) async {
              try {
                await actions.hide(post.fullname);
              } catch (_) {
                return;
              }
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: const Text('Post hidden'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () => actions.unhide(post.fullname),
                    ),
                    duration: const Duration(seconds: 4),
                  ),
                );
            }
          : null,
      onPostUnhide: actions != null && !filterHidden
          ? (post) async {
              final feedNotifier = ref.read(feedPageProvider(config).notifier);
              feedNotifier.removeItem((p) => p.fullname == post.fullname);
              await handleUnhide(
                actions,
                post.fullname,
                context,
                onUndo: () async {
                  await feedNotifier.refresh();
                },
              );
            }
          : null,
      onPostBlock: account != null
          ? (post) => handleBlockUser(
              context: context,
              notifier: ref.read(blockActionProvider.notifier),
              username: post.author,
            )
          : null,
      onPostTap: (post) => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => PostDetailScreen(post: post))),
      onSubredditTap:
          onSubredditTapOverride ??
          (post) => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  SubredditFeedScreen(subredditName: post.subreddit.name),
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

    // Wrap with prefetcher when enabled.
    final settings = ref.watch(appSettingsProvider);
    final content = settings.prefetchMedia
        ? FeedMediaPrefetcher(
            posts: state.items,
            scrollController: scrollController,
            child: postList,
          )
        : postList;

    // Wrapping with status banners when cached/stale/error content is shown.
    if (state.isLoading && state.items.isNotEmpty) {
      return Column(
        children: [
          const LinearProgressIndicator(),
          if (statusBanner != null) statusBanner,
          Expanded(child: content),
        ],
      );
    }

    if (statusBanner != null) {
      return Column(
        children: [
          statusBanner,
          Expanded(child: content),
        ],
      );
    }

    return content;
  }
}
