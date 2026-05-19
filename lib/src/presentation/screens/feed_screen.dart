import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers.dart';
import '../../domain/enums/feed_sort.dart';
import '../utils/interaction_helpers.dart';
import '../widgets/post_list.dart';
import 'post_detail_screen.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  FeedSort _sort = FeedSort.hot;

  @override
  Widget build(BuildContext context) {
    final activeAccount = ref.watch(activeAccountProvider);
    final loggedIn = activeAccount != null;
    final voteOverrides = ref.watch(voteProvider);
    final saveOverrides = ref.watch(saveProvider);

    final feedAsync = loggedIn
        ? ref.watch(homeFeedProvider((sort: _sort, after: null)))
        : ref.watch(popularFeedProvider(null));
    final title = loggedIn ? 'fspez' : 'Popular';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (loggedIn)
            PopupMenuButton<FeedSort>(
              icon: const Icon(Icons.sort),
              onSelected: (sort) => setState(() => _sort = sort),
              itemBuilder: (_) => FeedSort.values.map((sort) {
                return PopupMenuItem(
                  value: sort,
                  child: Text(sort.name),
                );
              }).toList(),
            ),
        ],
      ),
      body: feedAsync.when(
        data: (feed) => PostList(
          posts: feed.posts,
          voteOverrides: voteOverrides,
          saveOverrides: saveOverrides,
          onPostVote: (fullname, dir) => handleVote(ref.read(voteProvider.notifier), fullname, dir),
          onPostSave: (fullname) => handleSave(ref.read(saveProvider.notifier), fullname, context),
          onPostTap: (post) => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PostDetailScreen(post: post),
            ),
          ),
          emptyMessage: loggedIn
              ? 'No posts yet.'
              : 'No posts yet. Log in to see your home feed.',
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 40),
                const SizedBox(height: 8),
                Text('$err', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
