import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/app_settings.dart';
import '../../domain/enums/feed_density.dart';
import '../../domain/models/post.dart';
import '../../domain/enums/vote_direction.dart';
import 'media_viewer.dart';
import 'video_playback_coordinator.dart';
import 'post_metadata.dart';
import 'post_action_bar.dart';
import 'post_inline_video.dart';
import 'feed_media_tile.dart';
import 'post_card_overlay.dart';
import 'title_with_thumbnail.dart';

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
  final VoidCallback? onBlock;
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
    this.onBlock,
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
                PostMetadataRow(
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
                  onBlock: widget.onBlock,
                ),
                const SizedBox(height: 2),
                PostTitleWithThumbnail(
                  post: widget.post,
                  thumbnailUrl: _compactThumbnailUrl,
                  theme: theme,
                  maxLines: titleMaxLines,
                ),
              ] else if (hasFeedMedia) ...[
                PostMetadataRow(
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
                  onBlock: widget.onBlock,
                ),
                const SizedBox(height: 6),
                PostTitleWithThumbnail(
                  post: widget.post,
                  thumbnailUrl: null,
                  theme: theme,
                  maxLines: titleMaxLines,
                ),
                const SizedBox(height: 8),
                _buildMediaSection(theme, cs, density: density),
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
                PostMetadataRow(
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
                  onBlock: widget.onBlock,
                ),
                const SizedBox(height: 2),
                PostTitleWithThumbnail(
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
              PostActionBar(
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
      mediaWidget = InlineVideoPlayer(
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
        maxHeight: mediaMaxHeight,
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
        maxHeight: mediaMaxHeight,
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
        maxHeight: mediaMaxHeight,
      );
    }

    if (mediaWidget == null) return const SizedBox.shrink();

    if (shouldBlur) {
      return PostCardSensitiveOverlay(
        isNsfw: post.isNsfw,
        isSpoiler: post.isSpoiler,
        onReveal: () => setState(() => _sensitiveRevealed = true),
        child: mediaWidget,
      );
    }

    return mediaWidget;
  }
}
