import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers.dart';
import '../../domain/models/post.dart';
import '../../domain/enums/feed_sort.dart';
import '../widgets/post_card.dart';
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
        data: (feed) => _FeedList(
          posts: feed.posts,
          onPostTap: (post) => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PostDetailScreen(post: post),
            ),
          ),
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

class _FeedList extends StatelessWidget {
  final List<Post> posts;
  final void Function(Post post)? onPostTap;

  const _FeedList({required this.posts, this.onPostTap});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const Center(child: Text('No posts yet. Log in to see your home feed.'));
    }

    return ListView.separated(
      itemCount: posts.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final post = posts[index];
        return PostCard(
          post: post,
          onTap: onPostTap != null ? () => onPostTap!(post) : null,
        );
      },
    );
  }
}
