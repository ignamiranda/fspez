import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/models/comment.dart';
import '../../domain/enums/vote_direction.dart';
import '../utils/format_utils.dart';
import 'award_badge.dart';
import 'reddit_body.dart';
import 'user_flair_chip.dart';

/// Maximum comment depth before truncation, matching old Reddit's MAX_RECURSION.
/// Comments at this depth or beyond show a "Continue this thread" link instead
/// of rendering further nested children.
const kMaxCommentDepth = 10;

class CommentTree extends StatefulWidget {
  final Map<String, GlobalKey>? commentKeys;
  final Comment comment;
  final Map<String, VoteDirection> voteOverrides;
  final void Function(String fullname, VoteDirection direction)? onVote;
  final Map<String, bool> saveOverrides;
  final void Function(String fullname)? onSave;
  final void Function(String fullname, String author, String? body)? onReply;
  final void Function(String author)? onAuthorTap;
  final void Function(String fullname)? onDelete;
  final void Function(String fullname)? onEdit;
  final void Function(String author)? onBlock;
  final void Function(String fullname, String? subreddit)? onReport;
  final bool showAwards;

  const CommentTree({
    super.key,
    this.commentKeys,
    required this.comment,
    this.voteOverrides = const {},
    this.onVote,
    this.saveOverrides = const {},
    this.onSave,
    this.onReply,
    this.onAuthorTap,
    this.onDelete,
    this.onEdit,
    this.onBlock,
    this.onReport,
    this.showAwards = true,
  });

  @override
  State<CommentTree> createState() => _CommentTreeState();
}

class _CommentTreeState extends State<CommentTree> {
  bool? _userCollapsed;
  bool _showTruncated = false;

  bool get _isCollapsed => _userCollapsed ?? widget.comment.isCollapsed;

  void _toggleCollapse() {
    setState(() {
      _userCollapsed = !(_userCollapsed ?? widget.comment.isCollapsed);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fullname = widget.comment.fullname;
    final effectiveVote = widget.voteOverrides[fullname] ?? widget.comment.vote;
    final effectiveSaved =
        widget.saveOverrides[fullname] ?? widget.comment.isSaved;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Container(
            constraints: const BoxConstraints(minHeight: 36),
            decoration: widget.comment.depth > 0
                ? BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                        width: min(widget.comment.depth, 5) * 12.0,
                      ),
                    ),
                  )
                : null,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _toggleCollapse,
                  child: Row(
                    children: [
                      InkWell(
                        onTap: _isCollapsed
                            ? _toggleCollapse
                            : () =>
                                widget.onAuthorTap?.call(widget.comment.author),
                        child: Text(
                          'u/${widget.comment.author}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (widget.comment.authorFlair != null) ...[
                        const SizedBox(width: 4),
                        Flexible(
                          child: UserFlairChip(
                            flair: widget.comment.authorFlair!,
                          ),
                        ),
                      ],
                      if (widget.comment.isSubmitter) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            'OP',
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                      if (widget.comment.isAdmin) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '[A]',
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ] else if (widget.comment.isModerator) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.shield,
                          size: 14,
                          color: theme.colorScheme.tertiary,
                        ),
                      ] else if (widget.comment.isApprovedSubmitter) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E88E5),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '[S]',
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '·',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Text(
                        timeAgo(widget.comment.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      if (widget.comment.isScoreHidden)
                        Text(
                          'score hidden',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      else
                        Text(
                          '${widget.comment.score} pts',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      if (widget.comment.isControversial) ...[
                        const SizedBox(width: 4),
                        Text(
                          '†',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      if (widget.showAwards &&
                          widget.comment.awardCount > 0) ...[
                        const SizedBox(width: 8),
                        AwardBadge(
                          awardCount: widget.comment.awardCount,
                          awards: widget.comment.awards,
                        ),
                      ],
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _toggleCollapse,
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child: _isCollapsed
                        ? const SizedBox.shrink()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              RedditBody(widget.comment.body),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _CommentActionButton(
                                    icon: Icons.arrow_upward_outlined,
                                    activeIcon: Icons.arrow_upward,
                                    isActive:
                                        effectiveVote == VoteDirection.upvote,
                                    color: effectiveVote == VoteDirection.upvote
                                        ? theme.colorScheme.primary
                                        : null,
                                    onTap: () => widget.onVote?.call(
                                      fullname,
                                      VoteDirection.upvote,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  _CommentActionButton(
                                    icon: Icons.arrow_downward_outlined,
                                    activeIcon: Icons.arrow_downward,
                                    isActive:
                                        effectiveVote == VoteDirection.downvote,
                                    color:
                                        effectiveVote == VoteDirection.downvote
                                            ? theme.colorScheme.secondary
                                            : null,
                                    onTap: () => widget.onVote?.call(
                                      fullname,
                                      VoteDirection.downvote,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (widget.onReply != null)
                                    _CommentActionButton(
                                      icon: Icons.reply_outlined,
                                      onTap: () => widget.onReply!(
                                        widget.comment.fullname,
                                        widget.comment.author,
                                        widget.comment.body,
                                      ),
                                    )
                                  else
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 6,
                                      ),
                                      child: Icon(
                                        Icons.reply_outlined,
                                        size: 18,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  _CommentActionButton(
                                    icon: Icons.bookmark_outline,
                                    activeIcon: Icons.bookmark,
                                    isActive: effectiveSaved,
                                    color: effectiveSaved
                                        ? theme.colorScheme.tertiary
                                        : null,
                                    onTap: () => widget.onSave?.call(fullname),
                                  ),
                                  const SizedBox(width: 16),
                                  PopupMenuButton<String>(
                                    icon: Icon(
                                      Icons.more_horiz,
                                      size: 16,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    onSelected: (value) {
                                      switch (value) {
                                        case 'copy_link':
                                          final postId = widget.comment.postId
                                              .replaceFirst('t3_', '');
                                          String link;
                                          if (widget.comment.subreddit !=
                                              null) {
                                            link =
                                                'https://www.reddit.com/r/${widget.comment.subreddit}/comments/$postId/_/${widget.comment.id}/';
                                          } else {
                                            link =
                                                'https://www.reddit.com/comments/$postId/_/${widget.comment.id}/';
                                          }
                                          Clipboard.setData(
                                              ClipboardData(text: link));
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text('Copied')),
                                          );
                                        case 'copy_body':
                                          Clipboard.setData(ClipboardData(
                                              text: widget.comment.body));
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text('Copied')),
                                          );
                                        case 'report':
                                          widget.onReport?.call(
                                              widget.comment.fullname,
                                              widget.comment.subreddit);
                                        case 'edit':
                                          widget.onEdit?.call(fullname);
                                        case 'delete':
                                          widget.onDelete?.call(fullname);
                                        case 'block':
                                          widget.onBlock
                                              ?.call(widget.comment.author);
                                      }
                                    },
                                    itemBuilder: (context) {
                                      final items = <PopupMenuEntry<String>>[];
                                      items.add(
                                        const PopupMenuItem(
                                          value: 'copy_link',
                                          child: ListTile(
                                            leading: Icon(Icons.link, size: 16),
                                            title: Text('Copy Link'),
                                          ),
                                        ),
                                      );
                                      items.add(
                                        const PopupMenuItem(
                                          value: 'copy_body',
                                          child: ListTile(
                                            leading: Icon(Icons.content_copy,
                                                size: 16),
                                            title: Text('Copy Body'),
                                          ),
                                        ),
                                      );
                                      if (widget.onReport != null) {
                                        items.add(
                                          const PopupMenuItem(
                                            value: 'report',
                                            child: ListTile(
                                              leading: Icon(Icons.flag_outlined,
                                                  size: 16),
                                              title: Text('Report'),
                                            ),
                                          ),
                                        );
                                      }
                                      if (widget.onEdit != null) {
                                        items.add(
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: ListTile(
                                              leading: Icon(Icons.edit_outlined,
                                                  size: 16),
                                              title: Text('Edit'),
                                            ),
                                          ),
                                        );
                                      }
                                      if (widget.onDelete != null) {
                                        items.add(
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: ListTile(
                                              leading: Icon(
                                                  Icons.delete_outline,
                                                  size: 16),
                                              title: Text('Delete'),
                                            ),
                                          ),
                                        );
                                      }
                                      if (widget.onBlock != null) {
                                        items.add(
                                          const PopupMenuItem(
                                            value: 'block',
                                            child: ListTile(
                                              leading:
                                                  Icon(Icons.block, size: 16),
                                              title: Text('Block'),
                                            ),
                                          ),
                                        );
                                      }
                                      return items;
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: theme.colorScheme.outlineVariant,
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: _isCollapsed
                      ? const SizedBox.shrink()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _buildReplyList(theme),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildReplyList(ThemeData theme) {
    final truncated = <Comment>[];
    final visible = <Comment>[];

    for (final reply in widget.comment.replies) {
      // "more" placeholders are always visible — they're load-more buttons.
      if (reply.isMorePlaceholder) {
        visible.add(reply);
      } else if (!_showTruncated && reply.depth >= kMaxCommentDepth) {
        truncated.add(reply);
      } else {
        visible.add(reply);
      }
    }

    final children = <Widget>[];

    for (final reply in visible) {
      if (reply.isMorePlaceholder) {
        children.add(_buildMorePlaceholder(reply, theme));
      } else {
        widget.commentKeys?.putIfAbsent(reply.id, () => GlobalKey());
        children.add(CommentTree(
          key: widget.commentKeys?[reply.id],
          commentKeys: widget.commentKeys,
          comment: reply,
          voteOverrides: widget.voteOverrides,
          onVote: widget.onVote,
          saveOverrides: widget.saveOverrides,
          onSave: widget.onSave,
          onReply: widget.onReply,
          onAuthorTap: widget.onAuthorTap,
          onDelete: widget.onDelete,
          onEdit: widget.onEdit,
          onBlock: widget.onBlock,
          onReport: widget.onReport,
          showAwards: widget.showAwards,
        ));
      }
    }

    if (truncated.isNotEmpty) {
      final totalHidden = _countTruncated(truncated);
      children.add(_buildContinueThreadLink(totalHidden, theme));
    }

    return children;
  }

  Widget _buildMorePlaceholder(Comment reply, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0, top: 8, bottom: 8),
      child: InkWell(
        onTap: () {
          // For now, expanding a "more" placeholder is a no-op.
          // In a future pass this could load children from /api/morechildren.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${reply.moreCount} more replies')),
          );
        },
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Icon(
                Icons.unfold_more,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                reply.moreCount == 1
                    ? '1 more reply'
                    : '${reply.moreCount} more replies',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContinueThreadLink(int totalHidden, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 48, top: 8, bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _showTruncated = true),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Icon(
                Icons.arrow_downward,
                size: 14,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                totalHidden == 1
                    ? 'Continue this thread — 1 more reply'
                    : 'Continue this thread — $totalHidden more replies',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Recursively count all comments in the truncated sub-tree.
  int _countTruncated(List<Comment> comments) {
    int count = 0;
    for (final c in comments) {
      count += 1 + _countTruncated(c.replies);
    }
    return count;
  }
}

class _CommentActionButton extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final bool isActive;
  final Color? color;
  final VoidCallback? onTap;

  const _CommentActionButton({
    required this.icon,
    this.activeIcon,
    this.isActive = false,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        isActive && activeIcon != null ? activeIcon! : icon,
        size: 18,
        color: color ?? theme.colorScheme.onSurfaceVariant,
      ),
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      splashRadius: 24,
      padding: EdgeInsets.zero,
    );
  }
}
