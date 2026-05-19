import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers.dart';
import '../../domain/models/post.dart';
import '../../domain/models/comment.dart';
import '../../domain/enums/vote_direction.dart';
import '../utils/format_utils.dart';
import '../utils/interaction_helpers.dart';
import '../widgets/comment_tree.dart';

class PostDetailScreen extends ConsumerWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(
      postDetailProvider((
        subreddit: post.subreddit.name,
        postId: post.id,
      )),
    );
    final voteOverrides = ref.watch(voteProvider);
    final saveOverrides = ref.watch(saveProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'r/${post.subreddit.name}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
      body: detailAsync.when(
        data: (detail) => _buildBody(
          context,
          detail.comments,
          voteOverrides: voteOverrides,
          saveOverrides: saveOverrides,
          onVote: (fullname, dir) => handleVote(ref.read(voteProvider.notifier), fullname, dir),
          onSave: (fullname) => handleSave(ref.read(saveProvider.notifier), fullname, context),
        ),
        loading: () => _buildBody(context, const [],
            onVote: (fullname, dir) => handleVote(ref.read(voteProvider.notifier), fullname, dir),
            onSave: (fullname) => handleSave(ref.read(saveProvider.notifier), fullname, context)),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 40),
                const SizedBox(height: 8),
                Text('Failed to load comments',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<Comment> comments, {
    Map<String, VoteDirection> voteOverrides = const {},
    Map<String, bool> saveOverrides = const {},
    void Function(String fullname, VoteDirection direction)? onVote,
    void Function(String fullname)? onSave,
  }) {
    final theme = Theme.of(context);
    final postFullname = 't3_${post.id}';
    final postEffectiveVote = voteOverrides[postFullname];
    final postEffectiveSaved = saveOverrides[postFullname];

    return ListView(
      children: [
        _PostHeader(
          post: post,
          theme: theme,
          effectiveVote: postEffectiveVote,
          onVote: (dir) => onVote?.call(postFullname, dir),
          effectiveSaved: postEffectiveSaved,
          onSave: onSave != null ? () => onSave(postFullname) : null,
        ),
        if (post.selftext != null && post.selftext!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              post.selftext!,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        if (post.type == PostType.image && post.url != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                post.url!,
                width: double.infinity,
                fit: BoxFit.fitWidth,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        const Divider(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            comments.isEmpty ? 'Comments' : 'Comments (${comments.length})',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (comments.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('No comments yet')),
          )
        else
          ...comments.map((c) => CommentTree(
            comment: c,
            voteOverrides: voteOverrides,
            onVote: onVote,
            saveOverrides: saveOverrides,
            onSave: onSave,
          )),
      ],
    );
  }
}

class _PostHeader extends StatelessWidget {
  final Post post;
  final ThemeData theme;
  final VoteDirection? effectiveVote;
  final ValueChanged<VoteDirection>? onVote;
  final bool? effectiveSaved;
  final VoidCallback? onSave;

  const _PostHeader({
    required this.post,
    required this.theme,
    this.effectiveVote,
    this.onVote,
    this.effectiveSaved,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  post.subreddit.name.isNotEmpty
                      ? post.subreddit.name[0].toUpperCase()
                      : 'r',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        'r/${post.subreddit.name}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '· u/${post.author}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeAgo(post.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (post.isNsfw)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text('NSFW',
                      style: TextStyle(fontSize: 9, color: Colors.red)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            post.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              InkWell(
                onTap: () => onVote?.call(VoteDirection.upvote),
                child: Icon(
                  (effectiveVote ?? post.vote) == VoteDirection.upvote
                      ? Icons.arrow_upward
                      : Icons.arrow_upward_outlined,
                  size: 16,
                  color: (effectiveVote ?? post.vote) == VoteDirection.upvote
                      ? Colors.orange
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                formatCount(post.score),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => onVote?.call(VoteDirection.downvote),
                child: Icon(
                  (effectiveVote ?? post.vote) == VoteDirection.downvote
                      ? Icons.arrow_downward
                      : Icons.arrow_downward_outlined,
                  size: 16,
                  color: (effectiveVote ?? post.vote) == VoteDirection.downvote
                      ? Colors.blue
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: onSave,
                child: Icon(
                  (effectiveSaved ?? post.isSaved)
                      ? Icons.bookmark
                      : Icons.bookmark_outline,
                  size: 16,
                  color: (effectiveSaved ?? post.isSaved)
                      ? Colors.amber
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.chat_bubble_outline, size: 16),
              const SizedBox(width: 4),
              Text(
                formatCount(post.commentCount),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

}
