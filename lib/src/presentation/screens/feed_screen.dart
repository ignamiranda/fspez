import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers.dart';
import '../../domain/models/post.dart';
import '../../domain/enums/feed_sort.dart';
import '../../domain/enums/vote_direction.dart';
import '../widgets/post_card.dart';
import 'post_detail_screen.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  FeedSort _sort = FeedSort.hot;

  void _handleVote(String fullname, VoteDirection direction) {
    ref.read(voteProvider.notifier).toggle(fullname, direction);
  }

  Future<void> _handleSave(String fullname) async {
    try {
      await ref.read(saveProvider.notifier).toggle(fullname);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: $e'),
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

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
        data: (feed) => _FeedList(
          posts: feed.posts,
          voteOverrides: voteOverrides,
          saveOverrides: saveOverrides,
          onPostVote: _handleVote,
          onPostSave: _handleSave,
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
  final Map<String, VoteDirection> voteOverrides;
  final Map<String, bool> saveOverrides;
  final void Function(String fullname, VoteDirection direction)? onPostVote;
  final void Function(String fullname)? onPostSave;
  final void Function(Post post)? onPostTap;

  const _FeedList({
    required this.posts,
    this.voteOverrides = const {},
    this.saveOverrides = const {},
    this.onPostVote,
    this.onPostSave,
    this.onPostTap,
  });

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
        final fullname = 't3_${post.id}';
        return PostCard(
          post: post,
          effectiveVote: voteOverrides[fullname],
          onVote: onPostVote != null
              ? (dir) => onPostVote!(fullname, dir)
              : null,
          effectiveSaved: saveOverrides[fullname],
          onSave: onPostSave != null
              ? () => onPostSave!(fullname)
              : null,
          onTap: onPostTap != null ? () => onPostTap!(post) : null,
        );
      },
    );
  }
}
