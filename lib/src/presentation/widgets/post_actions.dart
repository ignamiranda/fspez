import 'package:flutter/material.dart';
import '../../domain/models/post.dart';
import '../../domain/enums/vote_direction.dart';
import '../utils/format_utils.dart';
import '../utils/open_url.dart';
import 'award_badge.dart';
import 'user_flair_chip.dart';

class PostHeader extends StatelessWidget {
  final Post post;
  final VoidCallback? onSubredditTap;
  final VoidCallback? onAuthorTap;
  final bool showAwards;

  const PostHeader({
    super.key,
    required this.post,
    this.onSubredditTap,
    this.onAuthorTap,
    this.showAwards = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                    errorBuilder: (_, __, ___) =>
                        _LetterAvatar(name: post.subreddit.name, theme: theme),
                  )
                : _LetterAvatar(name: post.subreddit.name, theme: theme),
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
                child: InkWell(
                  onTap: onAuthorTap,
                  child: Text(
                    '· u/${post.author}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (post.authorFlair != null) ...[
                const SizedBox(width: 4),
                Flexible(child: UserFlairChip(flair: post.authorFlair!)),
              ],
              const SizedBox(width: 4),
              Text(
                timeAgo(post.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (showAwards && post.awardCount > 0) ...[
                const SizedBox(width: 4),
                AwardBadge(awardCount: post.awardCount),
              ],
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
                style:
                    TextStyle(fontSize: 9, color: theme.colorScheme.tertiary)),
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
        if (post.crosspostParent != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.tertiary),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              post.crosspostParent!.subreddit.name.isNotEmpty
                  ? 'Crosspost'
                  : 'Crosspost',
              style: TextStyle(
                fontSize: 9,
                color: theme.colorScheme.tertiary,
              ),
            ),
          ),
      ],
    );
  }
}

class _LetterAvatar extends StatelessWidget {
  final String name;
  final ThemeData theme;

  const _LetterAvatar({required this.name, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'r',
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class PostActions extends StatelessWidget {
  final Post post;
  final bool showAwards;
  final VoteDirection? effectiveVote;
  final ValueChanged<VoteDirection>? onVote;
  final bool? effectiveSaved;
  final VoidCallback? onSave;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onHide;
  final VoidCallback? onTap;

  const PostActions({
    super.key,
    required this.post,
    this.showAwards = true,
    this.effectiveVote,
    this.onVote,
    this.effectiveSaved,
    this.onSave,
    this.onEdit,
    this.onDelete,
    this.onHide,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            color:
                vote == VoteDirection.upvote ? theme.colorScheme.primary : null,
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
          if (post.type != PostType.self_ && post.url != null) ...[
            const SizedBox(width: 12),
            _ActionButton(
              icon: Icons.open_in_new,
              onTap: () => openUrl(post.url!),
            ),
          ],
          if (onEdit != null) ...[
            const SizedBox(width: 12),
            _ActionButton(
              icon: Icons.edit_outlined,
              onTap: onEdit,
            ),
          ],
          if (onDelete != null) ...[
            const SizedBox(width: 12),
            _ActionButton(
              icon: Icons.delete_outline,
              onTap: onDelete,
            ),
          ],
          if (onHide != null) ...[
            const SizedBox(width: 12),
            _ActionButton(
              icon: Icons.visibility_off_outlined,
              onTap: onHide,
            ),
          ],
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
