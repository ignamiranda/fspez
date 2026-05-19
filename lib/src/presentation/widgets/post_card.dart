import 'package:flutter/material.dart';
import '../../domain/models/post.dart';
import '../../domain/enums/vote_direction.dart';
import '../utils/format_utils.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoteDirection? effectiveVote;
  final ValueChanged<VoteDirection>? onVote;
  final bool? effectiveSaved;
  final VoidCallback? onSave;
  final VoidCallback? onTap;
  final VoidCallback? onSubredditTap;

  const PostCard({
    super.key,
    required this.post,
    this.effectiveVote,
    this.onVote,
    this.effectiveSaved,
    this.onSave,
    this.onTap,
    this.onSubredditTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme),
              const SizedBox(height: 8),
              Text(
                post.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (post.selftext != null && post.selftext!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  post.selftext!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (post.type == PostType.image && post.url != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.55,
                    ),
                    child: Image.network(
                      post.url!,
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
              if (post.thumbnailUrl != null &&
                  post.thumbnailUrl != 'self' &&
                  post.thumbnailUrl != 'default' &&
                  post.thumbnailUrl != 'nsfw') ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 200,
                      maxWidth: 300,
                    ),
                    child: Image.network(
                      post.thumbnailUrl!,
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              _buildActions(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        ClipOval(
          child: SizedBox(
            width: 24,
            height: 24,
            child: post.subreddit.iconUrl != null
                ? Image.network(
                    post.subreddit.iconUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _letterAvatar(theme),
                  )
                : _letterAvatar(theme),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: InkWell(
                  onTap: onSubredditTap,
                  child: Text(
                    'r/${post.subreddit.name}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
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
        if (post.isStickied)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.tertiary),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text('PINNED',
                style: TextStyle(fontSize: 9, color: theme.colorScheme.tertiary)),
          ),
        if (post.isNsfw)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.error),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text('NSFW',
                style: TextStyle(fontSize: 9, color: theme.colorScheme.error)),
          ),
      ],
    );
  }

  Widget _letterAvatar(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: Text(
        post.subreddit.name.isNotEmpty
            ? post.subreddit.name[0].toUpperCase()
            : 'r',
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  Widget _buildActions(ThemeData theme) {
    final vote = effectiveVote ?? post.vote;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ActionButton(
            icon: vote == VoteDirection.upvote
                ? Icons.arrow_upward
                : Icons.arrow_upward_outlined,
            label: formatCount(post.score),
            color: vote == VoteDirection.upvote
                ? theme.colorScheme.primary
                : null,
            onTap: () => onVote?.call(VoteDirection.upvote),
          ),
          if (post.upvoteRatio != null) ...[
            const SizedBox(width: 2),
            Text(
              '${(post.upvoteRatio! * 100).round()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(width: 4),
          _ActionButton(
            icon: vote == VoteDirection.downvote
                ? Icons.arrow_downward
                : Icons.arrow_downward_outlined,
            color: vote == VoteDirection.downvote
                ? theme.colorScheme.secondary
                : null,
            onTap: () => onVote?.call(VoteDirection.downvote),
          ),
          const SizedBox(width: 12),
          _ActionButton(
            icon: Icons.chat_bubble_outline,
            label: formatCount(post.commentCount),
            onTap: onTap,
          ),
          const SizedBox(width: 12),
          _ActionButton(
            icon: (effectiveSaved ?? post.isSaved)
                ? Icons.bookmark
                : Icons.bookmark_outline,
            color: (effectiveSaved ?? post.isSaved)
                ? theme.colorScheme.tertiary
                : null,
            onTap: onSave,
          ),
        ],
      ),
    );
  }

}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final Color? color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    this.label,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            if (label != null) ...[
              const SizedBox(width: 2),
              Text(
                label!,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
