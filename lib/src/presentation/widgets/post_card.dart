import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../data/app_settings.dart';
import '../../domain/models/post.dart';
import '../../domain/enums/vote_direction.dart';
import '../utils/format_utils.dart';
import '../utils/open_url.dart';
import 'media_viewer.dart';
import 'bottom_sheet_menu.dart';

class PostCard extends ConsumerStatefulWidget {
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

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  bool _sensitiveRevealed = false;

  bool get _hasThumbnail {
    final t = widget.post.thumbnailUrl;
    return t != null &&
        t != 'self' &&
        t != 'default' &&
        t != 'nsfw' &&
        t != 'spoiler';
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
    final vote = widget.effectiveVote ?? widget.post.vote;

    return InkWell(
      onTap: widget.onTap,
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
                post: widget.post,
                theme: theme,
                cs: cs,
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
                hasThumbnail: _hasThumbnail,
                theme: theme,
              ),
              if (widget.post.type == PostType.self_ &&
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
              _buildMediaSection(theme, cs),
              const SizedBox(height: 6),
              _PostActionBar(
                post: widget.post,
                theme: theme,
                cs: cs,
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

  Widget _buildMediaSection(ThemeData theme, ColorScheme cs) {
    final post = widget.post;
    final shouldBlur = _shouldBlur;

    Widget? mediaWidget;

    if (post.videoUrl != null) {
      mediaWidget = _InlineVideoPlayer(
        videoUrl: post.videoUrl!,
        thumbnailUrl: post.thumbnailUrl,
        onTap: () => MediaViewer.show(
          context,
          imageUrls: post.mediaUrls,
          videoUrl: post.videoUrl,
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
        ),
      );
    } else if (post.mediaUrls.length == 1) {
      mediaWidget = _MediaTile(
        imageUrl: post.mediaUrls.first,
        onTap: () => MediaViewer.show(
          context,
          imageUrls: post.mediaUrls,
        ),
      );
    } else if (post.type == PostType.image && post.url != null) {
      mediaWidget = _MediaTile(
        imageUrl: post.url!,
        onTap: () => MediaViewer.show(
          context,
          imageUrls: [post.url!],
        ),
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
    final labels = <String>[
      if (isNsfw) 'NSFW',
      if (isSpoiler) 'Spoiler',
    ];

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
              Container(
                color: Colors.black54,
              ),
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
    if (onHide != null) {
      primaryActions.add(BottomSheetAction(
        icon: Icons.visibility_off_outlined,
        label: 'Hide',
        onTap: () => onHide!(),
      ));
    }
    if (onUnhide != null) {
      primaryActions.add(BottomSheetAction(
        icon: Icons.visibility_outlined,
        label: 'Unhide',
        onTap: () => onUnhide!(),
      ));
    }
    if (onEdit != null) {
      authorActions.add(BottomSheetAction(
        icon: Icons.edit_outlined,
        label: 'Edit',
        onTap: () => onEdit!(),
      ));
    }
    if (onDelete != null) {
      authorActions.add(BottomSheetAction(
        icon: Icons.delete_outline,
        label: 'Delete',
        onTap: () => onDelete!(),
        isDestructive: true,
      ));
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
                    child: Icon(Icons.link,
                        size: 20, color: theme.colorScheme.onSurfaceVariant),
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
                style: TextStyle(
                    fontSize: 9,
                    color: cs.tertiary,
                    fontWeight: FontWeight.w700)),
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
                style: TextStyle(
                    fontSize: 9, color: cs.error, fontWeight: FontWeight.w700)),
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
            child: Text('SPOILER',
                style: TextStyle(
                    fontSize: 9,
                    color: cs.tertiary,
                    fontWeight: FontWeight.w700)),
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
          icon:
              downActive ? Icons.arrow_downward : Icons.arrow_downward_outlined,
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

/// Ensures only one inline video plays at a time across the feed.
class _InlineVideoManager {
  static VideoPlayerController? _activeController;

  /// Activates [controller], pausing any previously active one.
  static void activate(VideoPlayerController controller) {
    if (_activeController != null && _activeController != controller) {
      _activeController!.pause();
    }
    _activeController = controller;
    controller.play();
  }

  /// Deactivates [controller] if it was the active one.
  static void deactivate(VideoPlayerController controller) {
    if (_activeController == controller) {
      _activeController?.pause();
      _activeController = null;
    }
  }
}

/// An inline video player that auto-plays in the feed, preserving aspect ratio.
class _InlineVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final VoidCallback? onTap;

  const _InlineVideoPlayer({
    required this.videoUrl,
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
      setState(() {
        _controller = controller;
        _initialized = true;
      });
      _InlineVideoManager.activate(controller);
    } catch (_) {
      if (mounted) setState(() => _errored = true);
    }
  }

  @override
  void dispose() {
    if (_controller != null) {
      _InlineVideoManager.deactivate(_controller!);
      _controller!.dispose();
    }
    super.dispose();
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
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
    } else {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GestureDetector(onTap: widget.onTap, child: child),
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
        alignment: Alignment.center,
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
