import 'package:flutter/material.dart';
import '../../domain/enums/feed_density.dart';
import '../../domain/models/post.dart';
import '../utils/format_utils.dart';
import 'award_badge.dart';
import 'subreddit_icon.dart';
import 'user_flair_chip.dart';
import 'post_overflow_menu.dart';

class PostMetadataRow extends StatelessWidget {
  final Post post;
  final ThemeData theme;
  final ColorScheme cs;
  final FeedDensity density;
  final bool showAwards;
  final bool showStickiedIndicator;
  final VoidCallback? onSubredditTap;
  final VoidCallback? onAuthorTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onHide;
  final VoidCallback? onUnhide;
  final VoidCallback? onBlock;

  const PostMetadataRow({
    super.key,
    required this.post,
    required this.theme,
    required this.cs,
    required this.density,
    required this.showAwards,
    required this.showStickiedIndicator,
    this.onSubredditTap,
    this.onAuthorTap,
    this.onEdit,
    this.onDelete,
    this.onHide,
    this.onUnhide,
    this.onBlock,
  });

  @override
  Widget build(BuildContext context) {
    final compact = density == FeedDensity.compact;
    final content = compact
        ? CompactPostMetadata(
            post: post,
            theme: theme,
            cs: cs,
            showAwards: showAwards,
            showStickiedIndicator: showStickiedIndicator,
            onSubredditTap: onSubredditTap,
            onAuthorTap: onAuthorTap,
          )
        : ComfortablePostMetadata(
            post: post,
            theme: theme,
            cs: cs,
            showAwards: showAwards,
            showStickiedIndicator: showStickiedIndicator,
            onSubredditTap: onSubredditTap,
            onAuthorTap: onAuthorTap,
          );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: content),
        const SizedBox(width: 4),
        Padding(
          padding: EdgeInsets.only(top: compact ? 0 : 2),
          child: PostOverflowMenu(
            post: post,
            cs: cs,
            onEdit: onEdit,
            onDelete: onDelete,
            onHide: onHide,
            onUnhide: onUnhide,
            onBlock: onBlock,
          ),
        ),
      ],
    );
  }
}

class ComfortablePostMetadata extends StatelessWidget {
  final Post post;
  final ThemeData theme;
  final ColorScheme cs;
  final bool showAwards;
  final bool showStickiedIndicator;
  final VoidCallback? onSubredditTap;
  final VoidCallback? onAuthorTap;

  const ComfortablePostMetadata({
    super.key,
    required this.post,
    required this.theme,
    required this.cs,
    required this.showAwards,
    required this.showStickiedIndicator,
    this.onSubredditTap,
    this.onAuthorTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SubredditIcon(subreddit: post.subreddit, size: 20),
        const SizedBox(width: 6),
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
        if (post.authorFlair != null) ...[
          const SizedBox(width: 4),
          Flexible(child: UserFlairChip(flair: post.authorFlair!)),
        ],
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
        if (showAwards && post.awardCount > 0) ...[
          const SizedBox(width: 6),
          AwardBadge(awardCount: post.awardCount),
        ],
        if (showStickiedIndicator && post.isStickied) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              border: Border.all(color: cs.tertiary),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              'PINNED',
              style: TextStyle(
                fontSize: 9,
                color: cs.tertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
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
            child: Text(
              'NSFW',
              style: TextStyle(
                fontSize: 9,
                color: cs.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        if (post.isSpoiler) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              border: Border.all(color: cs.tertiary),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              'SPOILER',
              style: TextStyle(
                fontSize: 9,
                color: cs.tertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        if (post.crosspostParent != null) ...[
          const SizedBox(width: 6),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                border: Border.all(color: cs.tertiary),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                post.crosspostParent!.subreddit.name.isNotEmpty
                    ? 'Crossposted from r/${post.crosspostParent!.subreddit.name}'
                    : 'Crossposted post',
                style: TextStyle(
                  fontSize: 9,
                  color: cs.tertiary,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class CompactPostMetadata extends StatelessWidget {
  final Post post;
  final ThemeData theme;
  final ColorScheme cs;
  final bool showAwards;
  final bool showStickiedIndicator;
  final VoidCallback? onSubredditTap;
  final VoidCallback? onAuthorTap;

  const CompactPostMetadata({
    super.key,
    required this.post,
    required this.theme,
    required this.cs,
    required this.showAwards,
    required this.showStickiedIndicator,
    this.onSubredditTap,
    this.onAuthorTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SubredditIcon(subreddit: post.subreddit, size: 18),
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
        InkWell(
          onTap: onAuthorTap,
          child: Text(
            'u/${post.author}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          timeAgo(post.createdAt),
          style: theme.textTheme.labelMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        if (showAwards && post.awardCount > 0)
          PostCompactTag(label: '⭐ ${post.awardCount}', color: cs.tertiary),
        if (showStickiedIndicator && post.isStickied)
          PostCompactTag(label: 'PINNED', color: cs.tertiary),
        if (post.isNsfw) PostCompactTag(label: 'NSFW', color: cs.error),
        if (post.isSpoiler) PostCompactTag(label: 'SPOILER', color: cs.tertiary),
        if (post.crosspostParent != null)
          PostCompactTag(
            label: post.crosspostParent!.subreddit.name.isNotEmpty
                ? 'XPOST r/${post.crosspostParent!.subreddit.name}'
                : 'XPOST',
            color: cs.tertiary,
          ),
      ],
    );
  }
}

class PostCompactTag extends StatelessWidget {
  final String label;
  final Color color;

  const PostCompactTag({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w700,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
