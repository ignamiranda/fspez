import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/app_settings.dart';
import '../../domain/enums/feed_density.dart';
import '../../domain/models/post.dart';
import '../../domain/enums/vote_direction.dart';
import 'post_metadata.dart';
import 'post_action_bar.dart';
import 'post_body.dart';
import 'video_playback_coordinator.dart';
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
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final settings = ref.watch(appSettingsProvider);
    final density = settings.feedDensity;
    final showAwards = settings.showAwards;
    final compact = density == FeedDensity.compact;
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
          padding: EdgeInsets.symmetric(
            vertical: compact ? 4 : 10,
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
                  thumbnailUrl: null,
                  theme: theme,
                  isCompact: true,
                ),
                const SizedBox(height: 4),
                PostActionBar(
                  post: widget.post,
                  vote: vote,
                  score: widget.post.score,
                  commentCount: widget.post.commentCount,
                  isSaved: widget.effectiveSaved ?? widget.post.isSaved,
                  compact: true,
                  onVote: widget.onVote,
                  onSave: widget.onSave,
                  onTap: widget.onTap,
                ),
              ] else ...[
                PostBody(
                  post: widget.post,
                  vote: vote,
                  onVote: widget.onVote,
                  isSaved: widget.effectiveSaved ?? widget.post.isSaved,
                  onSave: widget.onSave,
                  onTap: widget.onTap,
                  showSelftext: showSelftext,
                  showAwards: showAwards,
                  showStickiedIndicator: widget.showStickiedIndicator,
                  onSubredditTap: widget.onSubredditTap,
                  onAuthorTap: widget.onAuthorTap,
                  onEdit: widget.onEdit,
                  onDelete: widget.onDelete,
                  onHide: widget.onHide,
                  onUnhide: widget.onUnhide,
                  onBlock: widget.onBlock,
                  videoPlaybackCoordinator: widget.videoPlaybackCoordinator,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
