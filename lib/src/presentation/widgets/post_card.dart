import 'package:flutter/material.dart';
import '../../domain/models/post.dart';
import '../../domain/enums/vote_direction.dart';
import '../utils/format_utils.dart';
import '../utils/open_url.dart';
import 'media_viewer.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoteDirection? effectiveVote;
  final ValueChanged<VoteDirection>? onVote;
  final bool? effectiveSaved;
  final VoidCallback? onSave;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onHide;
  final VoidCallback? onUnhide;
  final VoidCallback? onTap;
  final VoidCallback? onSubredditTap;
  final VoidCallback? onAuthorTap;

  const PostCard({
    super.key,
    required this.post,
    this.effectiveVote,
    this.onVote,
    this.effectiveSaved,
    this.onSave,
    this.onEdit,
    this.onDelete,
    this.onHide,
    this.onUnhide,
    this.onTap,
    this.onSubredditTap,
    this.onAuthorTap,
  });

  bool get _hasThumbnail {
    final t = post.thumbnailUrl;
    return t != null &&
        t != 'self' &&
        t != 'default' &&
        t != 'nsfw' &&
        t != 'spoiler';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final vote = effectiveVote ?? post.vote;

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: cs.outlineVariant, width: 0.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
        child: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MetadataRow(
                      post: post,
                      theme: theme,
                      cs: cs,
                      onSubredditTap: onSubredditTap,
                      onAuthorTap: onAuthorTap,
                      onEdit: onEdit,
                      onDelete: onDelete,
                      onHide: onHide,
                      onUnhide: onUnhide,
                    ),
                    const SizedBox(height: 2),
                    _TitleWithThumbnail(
                      post: post,
                      hasThumbnail: _hasThumbnail,
                      theme: theme,
                    ),
                    if (post.type == PostType.self_ &&
                        post.selftext != null &&
                        post.selftext!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          post.selftext!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (post.mediaUrls.length >= 2)
                      _MediaTile(
                        imageUrl: post.mediaUrls.first,
                        badgeText: '${post.mediaUrls.length}',
                        badgeIcon: Icons.photo_library_outlined,
                        onTap: () => MediaViewer.show(
                          context,
                          imageUrls: post.mediaUrls,
                        ),
                      )
                    else if (post.mediaUrls.length == 1)
                      _MediaTile(
                        imageUrl: post.mediaUrls.first,
                        onTap: () => MediaViewer.show(
                          context,
                          imageUrls: post.mediaUrls,
                        ),
                      )
                    else if (post.type == PostType.image &&
                        post.url != null)
                      _MediaTile(
                        imageUrl: post.url!,
                        onTap: () => MediaViewer.show(
                          context,
                          imageUrls: [post.url!],
                        ),
                      ),
                    const SizedBox(height: 6),
                    _PostActionBar(
                      post: post,
                      theme: theme,
                      cs: cs,
                      vote: vote,
                      score: post.score,
                      commentCount: post.commentCount,
                      isSaved: effectiveSaved ?? post.isSaved,
                      onVote: onVote,
                      onSave: onSave,
                      onTap: onTap,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _OverflowMenu extends StatelessWidget {
  final Post post;
  final ColorScheme cs;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onHide;
  final VoidCallback? onUnhide;

  const _OverflowMenu({
    required this.post,
    required this.cs,
    this.onEdit,
    this.onDelete,
    this.onHide,
    this.onUnhide,
  });

  @override
  Widget build(BuildContext context) {
    final entries = <PopupMenuEntry<String>>[];
    if (onEdit != null) {
      entries.add(const PopupMenuItem(value: 'edit', child: Text('Edit')));
    }
    if (onDelete != null) {
      entries.add(const PopupMenuItem(value: 'delete', child: Text('Delete')));
    }
    if (onHide != null) {
      entries.add(const PopupMenuItem(value: 'hide', child: Text('Hide')));
    }
    if (onUnhide != null) {
      entries.add(const PopupMenuItem(value: 'unhide', child: Text('Unhide')));
    }
    if (entries.isEmpty) return const SizedBox.shrink();

    return InkWell(
      onTap: () {
        final box = context.findRenderObject() as RenderBox;
        final offset = box.localToGlobal(Offset.zero);
        showMenu<String>(
          context: context,
          position: RelativeRect.fromLTRB(
            offset.dx,
            offset.dy,
            offset.dx + box.size.width,
            offset.dy + box.size.height,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          items: entries,
        ).then((value) {
          if (value == null) return;
          switch (value) {
            case 'edit':
              onEdit?.call();
            case 'delete':
              onDelete?.call();
            case 'hide':
              onHide?.call();
            case 'unhide':
              onUnhide?.call();
          }
        });
      },
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(Icons.more_horiz, size: 18, color: cs.onSurfaceVariant),
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color color;
  final Color activeColor;
  final VoidCallback onTap;

  const _VoteButton({
    required this.icon,
    required this.active,
    required this.color,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

class _TitleWithThumbnail extends StatelessWidget {
  final Post post;
  final bool hasThumbnail;
  final ThemeData theme;

  const _TitleWithThumbnail({
    required this.post,
    required this.hasThumbnail,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            post.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (hasThumbnail && post.type != PostType.image)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 70,
                height: 70,
                child: Image.network(
                  post.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(Icons.link, size: 20,
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MetadataRow extends StatelessWidget {
  final Post post;
  final ThemeData theme;
  final ColorScheme cs;
  final VoidCallback? onSubredditTap;
  final VoidCallback? onAuthorTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onHide;
  final VoidCallback? onUnhide;

  const _MetadataRow({
    required this.post,
    required this.theme,
    required this.cs,
    this.onSubredditTap,
    this.onAuthorTap,
    this.onEdit,
    this.onDelete,
    this.onHide,
    this.onUnhide,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onSubredditTap,
          child: Text(
            'r/${post.subreddit.name}',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.primary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('·', style: TextStyle(color: cs.onSurfaceVariant)),
        ),
        InkWell(
          onTap: onAuthorTap,
          child: Text(
            'u/${post.author}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('·', style: TextStyle(color: cs.onSurfaceVariant)),
        ),
        Text(
          timeAgo(post.createdAt),
          style: theme.textTheme.labelMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        if (post.isStickied) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              border: Border.all(color: cs.tertiary),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text('PINNED',
                style: TextStyle(fontSize: 9, color: cs.tertiary, fontWeight: FontWeight.w700)),
          ),
        ],
          if (post.isNsfw) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                border: Border.all(color: cs.error),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text('NSFW',
                  style: TextStyle(fontSize: 9, color: cs.error, fontWeight: FontWeight.w700)),
            ),
          ],
          const Spacer(),
          _OverflowMenu(
            post: post,
            cs: cs,
            onEdit: onEdit,
            onDelete: onDelete,
            onHide: onHide,
            onUnhide: onUnhide,
          ),
        ],
      );
  }
}

class _PostActionBar extends StatelessWidget {
  final Post post;
  final ThemeData theme;
  final ColorScheme cs;
  final VoteDirection vote;
  final int score;
  final int commentCount;
  final bool isSaved;
  final ValueChanged<VoteDirection>? onVote;
  final VoidCallback? onSave;
  final VoidCallback? onTap;

  const _PostActionBar({
    required this.post,
    required this.theme,
    required this.cs,
    required this.vote,
    required this.score,
    required this.commentCount,
    required this.isSaved,
    this.onVote,
    this.onSave,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final upActive = vote == VoteDirection.upvote;
    final downActive = vote == VoteDirection.downvote;

    return Row(
      children: [
        _VoteButton(
          icon: upActive ? Icons.arrow_upward : Icons.arrow_upward_outlined,
          active: upActive,
          color: upActive ? cs.primary : cs.onSurfaceVariant,
          activeColor: cs.primary,
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
        _VoteButton(
          icon: downActive ? Icons.arrow_downward : Icons.arrow_downward_outlined,
          active: downActive,
          color: downActive ? cs.secondary : cs.onSurfaceVariant,
          activeColor: cs.secondary,
          onTap: () => onVote?.call(VoteDirection.downvote),
        ),
        const SizedBox(width: 16),
        _ActionItem(
          icon: Icons.chat_bubble_outline,
          label: formatCount(commentCount),
          onTap: onTap,
          color: cs.onSurfaceVariant,
        ),
        const SizedBox(width: 16),
        _ActionItem(
          icon: isSaved ? Icons.bookmark : Icons.bookmark_outline,
          onTap: onSave,
          color: isSaved ? cs.primary : cs.onSurfaceVariant,
        ),
        if (post.type != PostType.self_ && post.url != null) ...[
          const SizedBox(width: 16),
          _ActionItem(
            icon: Icons.open_in_new,
            onTap: () => openUrl(post.url!),
            color: cs.onSurfaceVariant,
          ),
        ],
      ],
    );
  }
}

/// A tappable media preview tile used in the feed for images and galleries.
class _MediaTile extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onTap;
  final String? badgeText;
  final IconData? badgeIcon;

  const _MediaTile({
    required this.imageUrl,
    required this.onTap,
    this.badgeText,
    this.badgeIcon,
  });

  @override
  Widget build(BuildContext context) {
    final child = ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Stack(
        children: [
          Image.network(
            imageUrl,
            width: double.infinity,
            fit: BoxFit.fitWidth,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          if (badgeText != null)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (badgeIcon != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(badgeIcon, color: Colors.white, size: 14),
                      ),
                    Text(
                      badgeText!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GestureDetector(
        onTap: onTap,
        child: child,
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback? onTap;
  final Color color;

  const _ActionItem({
    required this.icon,
    this.label,
    this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
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
    );
  }
}
