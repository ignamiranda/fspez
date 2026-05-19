import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers.dart';
import '../../domain/models/post.dart';
import '../../domain/enums/vote_direction.dart';
import '../widgets/post_card.dart';
import 'post_detail_screen.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voteOverrides = ref.watch(voteProvider);
    final saveOverrides = ref.watch(saveProvider);
    final feedAsync = ref.watch(savedFeedProvider(null));

    return Scaffold(
      appBar: AppBar(title: const Text('Saved')),
      body: feedAsync.when(
        data: (feed) => _SavedList(
          posts: feed.posts,
          voteOverrides: voteOverrides,
          saveOverrides: saveOverrides,
          onPostVote: (fullname, direction) =>
              ref.read(voteProvider.notifier).toggle(fullname, direction),
          onPostSave: (fullname) async {
            try {
              await ref.read(saveProvider.notifier).toggle(fullname);
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Save failed: $e'),
                  duration: const Duration(seconds: 8),
                ),
              );
            }
          },
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
                Text('$err',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(savedFeedProvider(null)),
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

class _SavedList extends StatelessWidget {
  final List<Post> posts;
  final Map<String, VoteDirection> voteOverrides;
  final Map<String, bool> saveOverrides;
  final void Function(String fullname, VoteDirection direction)? onPostVote;
  final void Function(String fullname)? onPostSave;
  final void Function(Post post)? onPostTap;

  const _SavedList({
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
      return const Center(child: Text('No saved posts yet.'));
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
          onSave: onPostSave != null ? () => onPostSave!(fullname) : null,
          onTap: onPostTap != null ? () => onPostTap!(post) : null,
        );
      },
    );
  }
}
