import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/app_settings.dart';
import '../../domain/models/post.dart';
import '../../domain/enums/feed_density.dart';
import '../../domain/enums/vote_direction.dart';
import 'media_viewer.dart';
import 'post_inline_video.dart';
import 'video_playback_coordinator.dart';
import 'post_metadata.dart';
import 'post_action_bar.dart';
import 'title_with_thumbnail.dart';
import 'feed_media_tile.dart';
import 'sensitive_media_overlay.dart';

class PostBody extends ConsumerStatefulWidget {
  final Post post;
  final VoteDirection vote;
  final ValueChanged<VoteDirection>? onVote;
  final bool isSaved;
  final VoidCallback? onSave;
  final VoidCallback? onTap;
  final bool showSelftext;
  final bool showAwards;
  final bool showStickiedIndicator;
  final double? upvoteRatio;
  final VoidCallback? onSubredditTap;
  final VoidCallback? onAuthorTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onHide;
  final VoidCallback? onUnhide;
  final VoidCallback? onBlock;
  final VideoPlaybackCoordinator? videoPlaybackCoordinator;

  const PostBody({
    super.key,
    required this.post,
    required this.vote,
    this.onVote,
    required this.isSaved,
    this.onSave,
    this.onTap,
    this.showSelftext = false,
    this.showAwards = false,
    this.showStickiedIndicator = false,
    this.upvoteRatio,
    this.onSubredditTap,
    this.onAuthorTap,
    this.onEdit,
    this.onDelete,
    this.onHide,
    this.onUnhide,
    this.onBlock,
    this.videoPlaybackCoordinator,
  });

  @override
  ConsumerState<PostBody> createState() => _PostBodyState();
}

class _PostBodyState extends ConsumerState<PostBody> {
  bool _sensitiveRevealed = false;

  String? get _thumbnailUrl {
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

  bool get _shouldBlur {
    final settings = ref.read(appSettingsProvider);
    final post = widget.post;
    if (_sensitiveRevealed) return false;
    if (post.isNsfw && settings.nsfwBlur) return true;
    if (post.isSpoiler && settings.spoilerBlur) return true;
    return false;
  }

  bool get _hasMedia =>
      widget.post.videoUrl != null ||
      widget.post.mediaUrls.isNotEmpty ||
      (widget.post.type == PostType.image && widget.post.url != null);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PostMetadataRow(
          post: widget.post,
          theme: theme,
          cs: cs,
          density: FeedDensity.comfortable,
          showAwards: widget.showAwards,
          showStickiedIndicator: widget.showStickiedIndicator,
          onSubredditTap: widget.onSubredditTap,
          onAuthorTap: widget.onAuthorTap,
          onEdit: widget.onEdit,
          onDelete: widget.onDelete,
          onHide: widget.onHide,
          onUnhide: widget.onUnhide,
          onBlock: widget.onBlock,
        ),
        const SizedBox(height: 6),
        PostTitleWithThumbnail(
          post: widget.post,
          thumbnailUrl: _hasMedia ? null : _thumbnailUrl,
          theme: theme,
          isCompact: false,
        ),
        if (_hasMedia) ...[
          const SizedBox(height: 8),
          _buildMediaSection(theme, cs),
        ],
        if (widget.showSelftext &&
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
        const SizedBox(height: 6),
        PostActionBar(
          post: widget.post,
          vote: widget.vote,
          score: widget.post.score,
          commentCount: widget.post.commentCount,
          isSaved: widget.isSaved,
          upvoteRatio: widget.upvoteRatio,
          compact: false,
          onVote: widget.onVote,
          onSave: widget.onSave,
          onTap: widget.onTap,
        ),
      ],
    );
  }

  Widget _buildMediaSection(ThemeData theme, ColorScheme cs) {
    final post = widget.post;
    final shouldBlur = _shouldBlur;

    Widget? mediaWidget;

    if (post.videoUrl != null) {
      mediaWidget = InlineVideoPlayer(
        postKey: post.fullname,
        videoUrl: post.videoUrl!,
        thumbnailUrl: post.thumbnailUrl,
        videoPlaybackCoordinator: widget.videoPlaybackCoordinator ??
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
      mediaWidget = FeedMediaTile(
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
        maxHeight: 240,
      );
    } else if (post.mediaUrls.length == 1) {
      mediaWidget = FeedMediaTile(
        imageUrl: post.mediaUrls.first,
        onTap: () => MediaViewer.show(
          context,
          imageUrls: post.mediaUrls,
          isNsfw: post.isNsfw,
          isSpoiler: post.isSpoiler,
          initiallyRevealed: _sensitiveRevealed,
        ),
        maxHeight: 240,
      );
    } else if (post.type == PostType.image && post.url != null) {
      mediaWidget = FeedMediaTile(
        imageUrl: post.url!,
        onTap: () => MediaViewer.show(
          context,
          imageUrls: [post.url!],
          isNsfw: post.isNsfw,
          isSpoiler: post.isSpoiler,
          initiallyRevealed: _sensitiveRevealed,
        ),
        maxHeight: 240,
      );
    }

    if (mediaWidget == null) return const SizedBox.shrink();

    if (shouldBlur) {
      return SensitiveMediaOverlay(
        isNsfw: post.isNsfw,
        isSpoiler: post.isSpoiler,
        onReveal: () => setState(() => _sensitiveRevealed = true),
        child: mediaWidget,
      );
    }

    return mediaWidget;
  }
}
