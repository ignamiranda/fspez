import 'package:flutter/material.dart';
import '../../domain/enums/vote_direction.dart';
import '../../domain/models/post.dart';
import '../utils/format_utils.dart';
import '../utils/open_url.dart';
import 'vote_button.dart';

class PostActionBar extends StatelessWidget {
  final Post post;
  final VoteDirection vote;
  final int score;
  final int commentCount;
  final bool isSaved;
  final double? upvoteRatio;
  final bool compact;
  final ValueChanged<VoteDirection>? onVote;
  final VoidCallback? onSave;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onHide;
  final VoidCallback? onReport;

  const PostActionBar({
    super.key,
    required this.post,
    required this.vote,
    required this.score,
    required this.commentCount,
    required this.isSaved,
    this.upvoteRatio,
    this.compact = false,
    this.onVote,
    this.onSave,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onHide,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final upActive = vote == VoteDirection.upvote;
    final downActive = vote == VoteDirection.downvote;
    final showLabel = !compact;

    return Row(
      children: [
        PostVoteButton(
          icon: upActive ? Icons.arrow_upward : Icons.arrow_upward_outlined,
          active: upActive,
          color: upActive ? cs.primary : cs.onSurfaceVariant,
          activeColor: cs.primary,
          semanticLabel: upActive ? 'Upvoted' : 'Upvote',
          onTap: () => onVote?.call(VoteDirection.upvote),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            formatCount(score),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: upActive
                  ? cs.primary
                  : downActive
                      ? cs.secondary
                      : cs.onSurfaceVariant,
            ),
          ),
        ),
        PostVoteButton(
          icon:
              downActive ? Icons.arrow_downward : Icons.arrow_downward_outlined,
          active: downActive,
          color: downActive ? cs.secondary : cs.onSurfaceVariant,
          activeColor: cs.secondary,
          semanticLabel: downActive ? 'Downvoted' : 'Downvote',
          onTap: () => onVote?.call(VoteDirection.downvote),
        ),
        if (upvoteRatio != null) ...[
          const SizedBox(width: 2),
          Text(
            '${(upvoteRatio! * 100).round()}%',
            style: TextStyle(
              fontSize: compact ? 10 : 12,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
        SizedBox(width: compact ? 10 : 16),
        PostActionItem(
          icon: Icons.chat_bubble_outline,
          label: showLabel ? formatCount(commentCount) : null,
          semanticLabel: 'Comments',
          compact: compact,
          onTap: onTap,
          color: cs.onSurfaceVariant,
        ),
        SizedBox(width: compact ? 10 : 16),
        PostActionItem(
          icon: isSaved ? Icons.bookmark : Icons.bookmark_outline,
          semanticLabel: isSaved ? 'Unsave' : 'Save',
          compact: compact,
          onTap: onSave,
          color: isSaved ? cs.primary : cs.onSurfaceVariant,
        ),
        if (post.type != PostType.self_ && post.url != null) ...[
          SizedBox(width: compact ? 10 : 16),
          PostActionItem(
            icon: Icons.open_in_new,
            semanticLabel: 'Open link',
            compact: compact,
            onTap: () => openUrl(post.url!),
            color: cs.onSurfaceVariant,
          ),
        ],
        if (onEdit != null) ...[
          SizedBox(width: compact ? 10 : 16),
          PostActionItem(
            icon: Icons.edit_outlined,
            semanticLabel: 'Edit',
            compact: compact,
            onTap: onEdit,
            color: cs.onSurfaceVariant,
          ),
        ],
        if (onDelete != null) ...[
          SizedBox(width: compact ? 10 : 16),
          PostActionItem(
            icon: Icons.delete_outline,
            semanticLabel: 'Delete',
            compact: compact,
            onTap: onDelete,
            color: cs.onSurfaceVariant,
          ),
        ],
        if (onHide != null) ...[
          SizedBox(width: compact ? 10 : 16),
          PostActionItem(
            icon: Icons.visibility_off_outlined,
            semanticLabel: 'Hide',
            compact: compact,
            onTap: onHide,
            color: cs.onSurfaceVariant,
          ),
        ],
        if (onReport != null) ...[
          SizedBox(width: compact ? 10 : 16),
          PostActionItem(
            icon: Icons.flag_outlined,
            semanticLabel: 'Report',
            compact: compact,
            onTap: onReport,
            color: cs.onSurfaceVariant,
          ),
        ],
      ],
    );
  }
}

class PostActionItem extends StatelessWidget {
  final IconData icon;
  final String? label;
  final String semanticLabel;
  final VoidCallback? onTap;
  final Color color;
  final bool compact;

  const PostActionItem({
    super.key,
    required this.icon,
    this.label,
    required this.semanticLabel,
    this.onTap,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      enabled: onTap != null,
      child: Tooltip(
        message: semanticLabel,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: compact ? 10 : 11,
                horizontal: compact ? 8 : 10,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: compact ? 16 : 17, color: color),
                  if (label != null) ...[
                    const SizedBox(width: 3),
                    Text(
                      label!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
