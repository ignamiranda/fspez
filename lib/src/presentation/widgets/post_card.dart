import 'package:flutter/material.dart';
import '../../domain/models/post.dart';
import '../../domain/enums/vote_direction.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoteDirection? effectiveVote;
  final ValueChanged<VoteDirection>? onVote;
  final VoidCallback? onTap;

  const PostCard({
    super.key,
    required this.post,
    this.effectiveVote,
    this.onVote,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
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
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
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
                _timeAgo(post.createdAt),
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
            label: _formatCount(post.score),
            color: vote == VoteDirection.upvote ? Colors.orange : null,
            onTap: () => onVote?.call(VoteDirection.upvote),
          ),
          const SizedBox(width: 4),
          _ActionButton(
            icon: vote == VoteDirection.downvote
                ? Icons.arrow_downward
                : Icons.arrow_downward_outlined,
            color: vote == VoteDirection.downvote ? Colors.blue : null,
            onTap: () => onVote?.call(VoteDirection.downvote),
          ),
          const SizedBox(width: 12),
          _ActionButton(
            icon: Icons.chat_bubble_outline,
            label: _formatCount(post.commentCount),
            onTap: onTap,
          ),
          const SizedBox(width: 12),
          _ActionButton(
            icon: post.isSaved ? Icons.bookmark : Icons.bookmark_outline,
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count > 0 ? count.toString() : '';
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 30) return '${diff.inDays}d';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo';
    return '${(diff.inDays / 365).floor()}y';
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
