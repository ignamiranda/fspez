import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers.dart';
import '../utils/interaction_helpers.dart';
import '../widgets/post_list.dart';
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
          emptyMessage: 'No saved posts yet.',
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
