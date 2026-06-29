import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../data/app_settings.dart';
import '../../domain/enums/feed_density.dart';
import '../../domain/models/post.dart';
import '../../domain/enums/vote_direction.dart';
import '../utils/format_utils.dart';
import '../utils/open_url.dart';
import 'award_badge.dart';
import 'media_viewer.dart';
import 'bottom_sheet_menu.dart';
import 'user_flair_chip.dart';
import 'video_playback_coordinator.dart';
import 'report_sheet.dart';

class PostCard extends ConsumerStatefulWidget {
  final Post post;
  final VoteDirection? effectiveVote;
  final ValueChanged<VoteDirection>? onVote;
  final bool? effectiveSaved;
  final bool showStickiedIndicator;
  final VoidCallback? onSave;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onHide;
  final VoidCallback? onUnhide;
  final VoidCallback? onTap;
  final VoidCallback? onSubredditTap;
  final VoidCallback? onAuthorTap;
  final VideoPlaybackCoordinator? videoPlaybackCoordinator;

  const PostCard({
    super.key,
    required this.post,
    this.effectiveVote,
    this.onVote,
    this.effectiveSaved,
    this.showStickiedIndicator = false,
    this.onSave,
    this.onEdit,
    this.onDelete,
    this.onHide,
    this.onUnhide,
    this.onTap,
    this.onSubredditTap,
    this.onAuthorTap,
    this.videoPlaybackCoordinator,
  });

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  bool _sensitiveRevealed = false;

  String? get _compactThumbnailUrl {
    final thumbnail = widget.post.thumbnailUrl;
    if (thumbnail != null &&
        thumbnail != 'self' &&
        thumbnail != 'default' &&
        thumbnail != 'nsfw' &&
        thumbnail != 'spoiler') {
      return thumbnail;
    }
    if (widget.post.mediaUrls.isNotEmpty) return widget.post.mediaUrls.first;
    if (widget.post.type == PostType.image && widget.post.url != null) {
      return widget.post.url;
    }
    return null;
  }

  /// Whether this post's media should be blurred based on settings.
  bool get _shouldBlur {
    final settings = ref.read(appSettingsProvider);
    final post = widget.post;
    if (_sensitiveRevealed) return false;
    if (post.isNsfw && settings.nsfwBlur) return true;
    if (post.isSpoiler && settings.spoilerBlur) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final settings = ref.watch(appSettingsProvider);
    final density = settings.feedDensity;
    final showAwards = settings.showAwards;
    final compact = density == FeedDensity.compact;
    final hasFeedMedia =
        widget.post.videoUrl != null ||
        widget.post.mediaUrls.isNotEmpty ||
        (widget.post.type == PostType.image && widget.post.url != null);
    final titleMaxLines = compact ? 1 : 2;
    final showSelftext = density == FeedDensity.comfortable;
    final vote = widget.effectiveVote ?? widget.post.vote;

    return InkWell(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: cs.outlineVariant, width: 0.5),
          ),
        ),
        padding: EdgeInsets.symmetric(
          vertical: compact ? 4 : 10,
          horizontal: 0,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 12,
            top: compact ? 4 : 10,
            bottom: compact ? 4 : 10,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (compact) ...[
                _MetadataRow(
                  post: widget.post,
                  theme: theme,
                  cs: cs,
                  density: density,
                  showAwards: showAwards,
                  showStickiedIndicator: widget.showStickiedIndicator,
                  onSubredditTap: widget.onSubredditTap,
                  onAuthorTap: widget.onAuthorTap,
                  onEdit: widget.onEdit,
                  onDelete: widget.onDelete,
                  onHide: widget.onHide,
                  onUnhide: widget.onUnhide,
                ),
                const SizedBox(height: 2),
                _TitleWithThumbnail(
                  post: widget.post,
                  thumbnailUrl: _compactThumbnailUrl,
                  theme: theme,
                  maxLines: titleMaxLines,
                ),
              ] else if (hasFeedMedia) ...[
                _MetadataRow(
                  post: widget.post,
                  theme: theme,
                  cs: cs,
                  density: density,
                  showAwards: showAwards,
                  showStickiedIndicator: widget.showStickiedIndicator,
                  onSubredditTap: widget.onSubredditTap,
                  onAuthorTap: widget.onAuthorTap,
                  onEdit: widget.onEdit,
                  onDelete: widget.onDelete,
                  onHide: widget.onHide,
                  onUnhide: widget.onUnhide,
                ),
                const SizedBox(height: 6),
                _buildMediaSection(theme, cs, density: density),
                const SizedBox(height: 8),
                _TitleWithThumbnail(
                  post: widget.post,
                  thumbnailUrl: null,
                  theme: theme,
                  maxLines: titleMaxLines,
                ),
                if (showSelftext &&
                    widget.post.type == PostType.self_ &&
                    widget.post.selftext != null &&
                    widget.post.selftext!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      widget.post.selftext!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ] else ...[
                _MetadataRow(
                  post: widget.post,
                  theme: theme,
                  cs: cs,
                  density: density,
                  showAwards: showAwards,
                  showStickiedIndicator: widget.showStickiedIndicator,
                  onSubredditTap: widget.onSubredditTap,
                  onAuthorTap: widget.onAuthorTap,
                  onEdit: widget.onEdit,
                  onDelete: widget.onDelete,
                  onHide: widget.onHide,
                  onUnhide: widget.onUnhide,
                ),
                const SizedBox(height: 2),
                _TitleWithThumbnail(
                  post: widget.post,
                  thumbnailUrl: _compactThumbnailUrl,
                  theme: theme,
                  maxLines: titleMaxLines,
                ),
                if (showSelftext &&
                    widget.post.type == PostType.self_ &&
                    widget.post.selftext != null &&
                    widget.post.selftext!.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: compact ? 2 : 4),
                    child: Text(
                      widget.post.selftext!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                _buildMediaSection(theme, cs, density: density),
              ],
              SizedBox(height: compact ? 4 : 6),
              _PostActionBar(
                post: widget.post,
                theme: theme,
                cs: cs,
                density: density,
                vote: vote,
                score: widget.post.score,
                commentCount: widget.post.commentCount,
                isSaved: widget.effectiveSaved ?? widget.post.isSaved,
                onVote: widget.onVote,
                onSave: widget.onSave,
                onTap: widget.onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaSection(
    ThemeData theme,
    ColorScheme cs, {
    required FeedDensity density,
  }) {
    final post = widget.post;
    final shouldBlur = _shouldBlur;
    final mediaMaxHeight = density == FeedDensity.compact ? 140.0 : 240.0;

    Widget? mediaWidget;

    if (post.videoUrl != null) {
      mediaWidget = _InlineVideoPlayer(
        postKey: post.fullname,
        videoUrl: post.videoUrl!,
        thumbnailUrl: post.thumbnailUrl,
        videoPlaybackCoordinator:
            widget.videoPlaybackCoordinator ??
            GlobalVideoPlaybackCoordinator.instance,
        onTap: () => MediaViewer.show(
          context,
          imageUrls: post.mediaUrls,
          videoUrl: post.videoUrl,
          isNsfw: post.isNsfw,
          isSpoiler: post.isSpoiler,
          initiallyRevealed: _sensitiveRevealed,
        ),
      );
    } else if (post.mediaUrls.length >= 2) {
      mediaWidget = _MediaTile(
        imageUrl: post.mediaUrls.first,
        badgeText: '${post.mediaUrls.length}',
        badgeIcon: Icons.photo_library_outlined,
        onTap: () => MediaViewer.show(
          context,
          imageUrls: post.mediaUrls,
          isNsfw: post.isNsfw,
          isSpoiler: post.isSpoiler,
          initiallyRevealed: _sensitiveRevealed,
        ),
        maxHeight: mediaMaxHeight,
      );
    } else if (post.mediaUrls.length == 1) {
      mediaWidget = _MediaTile(
        imageUrl: post.mediaUrls.first,
        onTap: () => MediaViewer.show(
          context,
          imageUrls: post.mediaUrls,
          isNsfw: post.isNsfw,
          isSpoiler: post.isSpoiler,
          initiallyRevealed: _sensitiveRevealed,
        ),
        maxHeight: mediaMaxHeight,
      );
    } else if (post.type == PostType.image && post.url != null) {
      mediaWidget = _MediaTile(
        imageUrl: post.url!,
        onTap: () => MediaViewer.show(
          context,
          imageUrls: [post.url!],
          isNsfw: post.isNsfw,
          isSpoiler: post.isSpoiler,
          initiallyRevealed: _sensitiveRevealed,
        ),
        maxHeight: mediaMaxHeight,
      );
    }

    if (mediaWidget == null) return const SizedBox.shrink();

    if (shouldBlur) {
      return _SensitiveOverlay(
        isNsfw: post.isNsfw,
        isSpoiler: post.isSpoiler,
        onReveal: () => setState(() => _sensitiveRevealed = true),
        child: mediaWidget,
      );
    }

    return mediaWidget;
  }
}

/// Overlay that blurs sensitive content and shows a tap-to-reveal button.
class _SensitiveOverlay extends StatelessWidget {
  final bool isNsfw;
  final bool isSpoiler;
  final VoidCallback onReveal;
  final Widget child;

  const _SensitiveOverlay({
    required this.isNsfw,
    required this.isSpoiler,
    required this.onReveal,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = <String>[if (isNsfw) 'NSFW', if (isSpoiler) 'Spoiler'];

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GestureDetector(
        onTap: onReveal,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            alignment: Alignment.center,
            fit: StackFit.passthrough,
            children: [
              // Blurred content behind
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: child,
              ),
              // Dark scrim
              Container(color: Colors.black54),
              // Label + reveal button
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: labels.map((label) {
                      final color = label == 'NSFW'
                          ? theme.colorScheme.error
                          : theme.colorScheme.tertiary;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: color),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to reveal',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
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
    final primaryActions = <BottomSheetAction>[];
    final authorActions = <BottomSheetAction>[];

    // Copy actions
    primaryActions.add(
      BottomSheetAction(
        icon: Icons.link,
        label: 'Copy Reddit link',
        onTap: () {
          final link = 'https://www.reddit.com${post.permalink}';
          Clipboard.setData(ClipboardData(text: link));
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Copied')));
        },
      ),
    );

    if (post.url != null &&
        !post.url!.startsWith('https://www.reddit.com') &&
        post.type != PostType.self_) {
      primaryActions.add(
        BottomSheetAction(
          icon: Icons.open_in_new,
          label: 'Copy external link',
          onTap: () {
            Clipboard.setData(ClipboardData(text: post.url!));
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Copied')));
          },
        ),
      );
    }

    final textToCopy = post.selftext != null && post.selftext!.isNotEmpty
        ? '${post.title}\n\n${post.selftext}'
        : post.title;
    primaryActions.add(
      BottomSheetAction(
        icon: Icons.content_copy,
        label: 'Copy text',
        onTap: () {
          Clipboard.setData(ClipboardData(text: textToCopy));
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Copied')));
        },
      ),
    );

    primaryActions.add(
      BottomSheetAction(
        icon: Icons.flag_outlined,
        label: 'Report',
        onTap: () => showReportSheet(
          context,
          thingId: post.fullname,
          subreddit: post.subreddit.name,
        ),
      ),
    );

    if (onHide != null) {
      primaryActions.add(
        BottomSheetAction(
          icon: Icons.visibility_off_outlined,
          label: 'Hide',
          onTap: () => onHide!(),
        ),
      );
    }
    if (onUnhide != null) {
      primaryActions.add(
        BottomSheetAction(
          icon: Icons.visibility_outlined,
          label: 'Unhide',
          onTap: () => onUnhide!(),
        ),
      );
    }
    if (onEdit != null) {
      authorActions.add(
        BottomSheetAction(
          icon: Icons.edit_outlined,
          label: 'Edit',
          onTap: () => onEdit!(),
        ),
      );
    }
    if (onDelete != null) {
      authorActions.add(
        BottomSheetAction(
          icon: Icons.delete_outline,
          label: 'Delete',
          onTap: () => onDelete!(),
          isDestructive: true,
        ),
      );
    }

    if (primaryActions.isEmpty && authorActions.isEmpty) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: () => showPostActionSheet(
        context,
        primaryActions: primaryActions,
        authorActions: authorActions,
      ),
      borderRadius: BorderRadius.circular(4),
      child: Semantics(
        button: true,
        label: 'More actions',
        child: Tooltip(
          message: 'More actions',
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            child: Center(
              child: Icon(
                Icons.more_horiz,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color color;
  final Color activeColor;
  final String semanticLabel;
  final VoidCallback onTap;

  const _VoteButton({
    required this.icon,
    required this.active,
    required this.color,
    required this.activeColor,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: semanticLabel,
      enabled: true,
      child: Tooltip(
        message: semanticLabel,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(4),
            child: Center(child: Icon(icon, size: 20, color: color)),
          ),
        ),
      ),
    );
  }
}

class _TitleWithThumbnail extends StatelessWidget {
  final Post post;
  final String? thumbnailUrl;
  final ThemeData theme;
  final int maxLines;

  const _TitleWithThumbnail({
    required this.post,
    required this.thumbnailUrl,
    required this.theme,
    required this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final isCompactTitle = maxLines == 1;
    final thumbnailSize = isCompactTitle ? 48.0 : 56.0;
    final thumbnailPadding = isCompactTitle ? 2.0 : 3.0;
    if (isCompactTitle && thumbnailUrl != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ThumbnailFrame(
            theme: theme,
            thumbnailUrl: thumbnailUrl!,
            size: thumbnailSize,
            padding: thumbnailPadding,
            iconSize: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                post.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      );
    }

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
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (thumbnailUrl != null)
          Padding(
            padding: EdgeInsets.only(left: 8, top: isCompactTitle ? 1 : 0),
            child: _ThumbnailFrame(
              theme: theme,
              thumbnailUrl: thumbnailUrl!,
              size: thumbnailSize,
              padding: thumbnailPadding,
              iconSize: isCompactTitle ? 18 : 16,
            ),
          ),
      ],
    );
  }
}

class _ThumbnailFrame extends StatelessWidget {
  final ThemeData theme;
  final String thumbnailUrl;
  final double size;
  final double padding;
  final double iconSize;

  const _ThumbnailFrame({
    required this.theme,
    required this.thumbnailUrl,
    required this.size,
    required this.padding,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          thumbnailUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.link,
              size: iconSize,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
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

  const _MetadataRow({
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
  });

  @override
  Widget build(BuildContext context) {
    final compact = density == FeedDensity.compact;
    final content = compact
        ? _CompactMetadataContent(
            post: post,
            theme: theme,
            cs: cs,
            showAwards: showAwards,
            showStickiedIndicator: showStickiedIndicator,
            onSubredditTap: onSubredditTap,
            onAuthorTap: onAuthorTap,
          )
        : _ComfortableMetadataContent(
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
          child: _OverflowMenu(
            post: post,
            cs: cs,
            onEdit: onEdit,
            onDelete: onDelete,
            onHide: onHide,
            onUnhide: onUnhide,
          ),
        ),
      ],
    );
  }
}

class _ComfortableMetadataContent extends StatelessWidget {
  final Post post;
  final ThemeData theme;
  final ColorScheme cs;
  final bool showAwards;
  final bool showStickiedIndicator;
  final VoidCallback? onSubredditTap;
  final VoidCallback? onAuthorTap;

  const _ComfortableMetadataContent({
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
    final iconUrl = post.subreddit.iconUrl;
    return Row(
      children: [
        if (iconUrl != null && iconUrl.isNotEmpty) ...[
          ClipOval(
            child: Image.network(
              iconUrl,
              width: 20,
              height: 20,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(width: 6),
        ],
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

class _CompactMetadataContent extends StatelessWidget {
  final Post post;
  final ThemeData theme;
  final ColorScheme cs;
  final bool showAwards;
  final bool showStickiedIndicator;
  final VoidCallback? onSubredditTap;
  final VoidCallback? onAuthorTap;

  const _CompactMetadataContent({
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
    final iconUrl = post.subreddit.iconUrl;
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (iconUrl != null && iconUrl.isNotEmpty)
          ClipOval(
            child: Image.network(
              iconUrl,
              width: 18,
              height: 18,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
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
          _CompactTag(label: '⭐ ${post.awardCount}', color: cs.tertiary),
        if (showStickiedIndicator && post.isStickied)
          _CompactTag(label: 'PINNED', color: cs.tertiary),
        if (post.isNsfw) _CompactTag(label: 'NSFW', color: cs.error),
        if (post.isSpoiler) _CompactTag(label: 'SPOILER', color: cs.tertiary),
        if (post.crosspostParent != null)
          _CompactTag(
            label: post.crosspostParent!.subreddit.name.isNotEmpty
                ? 'XPOST r/${post.crosspostParent!.subreddit.name}'
                : 'XPOST',
            color: cs.tertiary,
          ),
      ],
    );
  }
}

class _CompactTag extends StatelessWidget {
  final String label;
  final Color color;

  const _CompactTag({required this.label, required this.color});

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

class _PostActionBar extends StatelessWidget {
  final Post post;
  final ThemeData theme;
  final ColorScheme cs;
  final FeedDensity density;
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
    required this.density,
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
    final compact = density == FeedDensity.compact;
    final showLabel = density != FeedDensity.compact;

    return Row(
      children: [
        _VoteButton(
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
        _VoteButton(
          icon: downActive
              ? Icons.arrow_downward
              : Icons.arrow_downward_outlined,
          active: downActive,
          color: downActive ? cs.secondary : cs.onSurfaceVariant,
          activeColor: cs.secondary,
          semanticLabel: downActive ? 'Downvoted' : 'Downvote',
          onTap: () => onVote?.call(VoteDirection.downvote),
        ),
        SizedBox(width: compact ? 10 : 16),
        _ActionItem(
          icon: Icons.chat_bubble_outline,
          label: showLabel ? formatCount(commentCount) : null,
          semanticLabel: 'Comments',
          compact: compact,
          onTap: onTap,
          color: cs.onSurfaceVariant,
        ),
        SizedBox(width: compact ? 10 : 16),
        _ActionItem(
          icon: isSaved ? Icons.bookmark : Icons.bookmark_outline,
          semanticLabel: isSaved ? 'Unsave' : 'Save',
          compact: compact,
          onTap: onSave,
          color: isSaved ? cs.primary : cs.onSurfaceVariant,
        ),
        if (post.type != PostType.self_ && post.url != null) ...[
          SizedBox(width: compact ? 10 : 16),
          _ActionItem(
            icon: Icons.open_in_new,
            semanticLabel: 'Open link',
            compact: compact,
            onTap: () => openUrl(post.url!),
            color: cs.onSurfaceVariant,
          ),
        ],
      ],
    );
  }
}

/// Ensures only one inline video plays at a time across the feed.
/// Fraction of the widget that must be visible to trigger auto-play.
const _kVideoVisibilityThreshold = 0.5;

/// An inline video player that auto-plays muted when mostly visible in the
/// viewport, pauses when scrolled out, and shows mute/unmute + play/pause
/// overlays.
class _InlineVideoPlayer extends StatefulWidget {
  final String postKey;
  final String videoUrl;
  final String? thumbnailUrl;
  final VoidCallback? onTap;
  final VideoPlaybackCoordinator videoPlaybackCoordinator;

  const _InlineVideoPlayer({
    required this.postKey,
    required this.videoUrl,
    required this.videoPlaybackCoordinator,
    this.thumbnailUrl,
    this.onTap,
  });

  @override
  State<_InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<_InlineVideoPlayer> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _errored = false;
  bool _isPlaying = false;
  bool _isMuted = true;
  double _lastVisibleFraction = 0;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );
    try {
      await controller.initialize();
      if (!mounted) return;
      // Start muted
      await controller.setVolume(0);
      controller.addListener(_onControllerUpdate);
      setState(() {
        _controller = controller;
        _initialized = true;
      });
      if (_lastVisibleFraction > _kVideoVisibilityThreshold) {
        _play();
      }
      // Do NOT auto-play immediately — visibility will trigger playback.
    } catch (_) {
      if (mounted) setState(() => _errored = true);
    }
  }

  @override
  void dispose() {
    if (_controller != null) {
      _controller!.removeListener(_onControllerUpdate);
      widget.videoPlaybackCoordinator.deactivate(_controller!);
      _controller!.dispose();
    }
    super.dispose();
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    final nowPlaying = _controller?.value.isPlaying ?? false;
    if (_isPlaying != nowPlaying) {
      setState(() => _isPlaying = nowPlaying);
      // If the video ended naturally, ensure the manager knows it's done.
      if (!nowPlaying && _controller != null) {
        widget.videoPlaybackCoordinator.deactivate(_controller!);
      }
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    _lastVisibleFraction = info.visibleFraction;
    if (!_initialized || _controller == null) return;
    final visible = info.visibleFraction > _kVideoVisibilityThreshold;
    if (visible && !_isPlaying) {
      _play();
    } else if (!visible && _isPlaying) {
      _pause();
    }
  }

  void _play() {
    if (_controller == null) return;
    // If video reached the end, seek to beginning before replaying.
    final value = _controller!.value;
    if (value.isCompleted) {
      _controller!.seekTo(Duration.zero);
    }
    widget.videoPlaybackCoordinator.activate(_controller!);
    if (mounted) setState(() => _isPlaying = true);
  }

  void _pause() {
    if (_controller == null) return;
    widget.videoPlaybackCoordinator.deactivate(_controller!);
    if (mounted) setState(() => _isPlaying = false);
  }

  void _togglePlayPause() {
    if (_controller == null) return;
    if (_isPlaying) {
      _pause();
    } else {
      _play();
    }
  }

  void _toggleMute() {
    if (_controller == null) return;
    final newMuted = !_isMuted;
    _controller!.setVolume(newMuted ? 0 : 1);
    if (mounted) setState(() => _isMuted = newMuted);
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (_errored) {
      child = widget.thumbnailUrl != null
          ? Image.network(
              widget.thumbnailUrl!,
              width: double.infinity,
              fit: BoxFit.fitWidth,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            )
          : const SizedBox.shrink();
    } else if (!_initialized || _controller == null) {
      child = widget.thumbnailUrl != null
          ? Stack(
              alignment: Alignment.center,
              children: [
                Image.network(
                  widget.thumbnailUrl!,
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
                const CircularProgressIndicator(
                  color: Colors.white54,
                  strokeWidth: 2,
                ),
              ],
            )
          : const AspectRatio(
              aspectRatio: 16 / 9,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
    } else {
      child = Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          ),
          // Overlay controls at the bottom-right
          Positioned(
            bottom: 8,
            right: 8,
            child: _VideoControlRow(
              isPlaying: _isPlaying,
              isMuted: _isMuted,
              onTogglePlayPause: _togglePlayPause,
              onToggleMute: _toggleMute,
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: VisibilityDetector(
        key: ValueKey('inline_video_${widget.postKey}_${widget.videoUrl}'),
        onVisibilityChanged: _onVisibilityChanged,
        child: GestureDetector(onTap: widget.onTap, child: child),
      ),
    );
  }
}

/// Small row of control buttons for inline video (play/pause + mute/unmute).
/// Each button stops tap propagation so the parent fullscreen gesture is not
/// triggered.
class _VideoControlRow extends StatelessWidget {
  final bool isPlaying;
  final bool isMuted;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onToggleMute;

  const _VideoControlRow({
    required this.isPlaying,
    required this.isMuted,
    required this.onTogglePlayPause,
    required this.onToggleMute,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ControlCircleButton(
          icon: isPlaying ? Icons.pause : Icons.play_arrow,
          onTap: onTogglePlayPause,
        ),
        const SizedBox(width: 6),
        _ControlCircleButton(
          icon: isMuted ? Icons.volume_off : Icons.volume_up,
          onTap: onToggleMute,
        ),
      ],
    );
  }
}

/// A small circular button with a white icon on a semi-transparent dark
/// background. Wrapped in its own [GestureDetector] to absorb the tap and
/// prevent the parent from opening the fullscreen viewer.
class _ControlCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ControlCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}

/// A tappable media preview tile used in the feed for images and galleries.
class _MediaTile extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onTap;
  final String? badgeText;
  final IconData? badgeIcon;
  final double maxHeight;

  const _MediaTile({
    required this.imageUrl,
    required this.onTap,
    this.badgeText,
    this.badgeIcon,
    this.maxHeight = 240,
  });

  @override
  Widget build(BuildContext context) {
    final child = ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.network(
              imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
            if (badgeText != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
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
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GestureDetector(onTap: onTap, child: child),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String? label;
  final String semanticLabel;
  final VoidCallback? onTap;
  final Color color;
  final bool compact;

  const _ActionItem({
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
