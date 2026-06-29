import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/models/comment.dart';
import '../../domain/enums/vote_direction.dart';
import '../utils/format_utils.dart';
import 'award_badge.dart';
import 'reddit_body.dart';
import 'user_flair_chip.dart';

class CommentTree extends StatefulWidget {
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
          child: GestureDetector(
            onTap: _toggleCollapse,
            behavior: HitTestBehavior.opaque,
            child: Container(
              constraints: const BoxConstraints(minHeight: 36),
              decoration: widget.comment.depth > 0
                  ? BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                          width: widget.comment.depth * 16.0,
                        ),
                      ),
                    )
                  : null,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          _toggleCollapse();
                          widget.onAuthorTap?.call(widget.comment.author);
                        },
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
                      if (widget.comment.isModerator) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.shield,
                          size: 14,
                          color: theme.colorScheme.tertiary,
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
                      if (_isCollapsed)
                        Icon(
                          Icons.unfold_more,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      Text(
                        '${widget.comment.score} pts',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (widget.showAwards &&
                          widget.comment.awardCount > 0) ...[
                        const SizedBox(width: 8),
                        AwardBadge(awardCount: widget.comment.awardCount),
                      ],
                    ],
                  ),
                  AnimatedSize(
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
                                  InkWell(
                                    onTap: () => widget.onVote?.call(
                                      fullname,
                                      VoteDirection.upvote,
                                    ),
                                    child: Icon(
                                      effectiveVote == VoteDirection.upvote
                                          ? Icons.arrow_upward
                                          : Icons.arrow_upward_outlined,
                                      size: 16,
                                      color:
                                          effectiveVote == VoteDirection.upvote
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  InkWell(
                                    onTap: () => widget.onVote?.call(
                                      fullname,
                                      VoteDirection.downvote,
                                    ),
                                    child: Icon(
                                      effectiveVote == VoteDirection.downvote
                                          ? Icons.arrow_downward
                                          : Icons.arrow_downward_outlined,
                                      size: 16,
                                      color:
                                          effectiveVote ==
                                              VoteDirection.downvote
                                          ? theme.colorScheme.secondary
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  if (widget.onReply != null)
                                    InkWell(
                                      onTap: () => widget.onReply!(
                                        widget.comment.fullname,
                                        widget.comment.author,
                                        widget.comment.body,
                                      ),
                                      child: Icon(
                                        Icons.reply_outlined,
                                        size: 16,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    )
                                  else
                                    Icon(
                                      Icons.reply_outlined,
                                      size: 16,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  const SizedBox(width: 16),
                                  InkWell(
                                    onTap: () => widget.onSave?.call(fullname),
                                    child: Icon(
                                      effectiveSaved
                                          ? Icons.bookmark
                                          : Icons.bookmark_outline,
                                      size: 16,
                                      color: effectiveSaved
                                          ? theme.colorScheme.tertiary
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  InkWell(
                                    onTap: () {
                                      final link =
                                          'https://www.reddit.com/comments/${widget.comment.postId}/_/${widget.comment.id}/';
                                      Clipboard.setData(
                                        ClipboardData(text: link),
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(content: Text('Copied')),
                                      );
                                    },
                                    child: Icon(
                                      Icons.link,
                                      size: 16,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  InkWell(
                                    onTap: () {
                                      Clipboard.setData(
                                        ClipboardData(
                                          text: widget.comment.body,
                                        ),
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(content: Text('Copied')),
                                      );
                                    },
                                    child: Icon(
                                      Icons.content_copy,
                                      size: 16,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (widget.onReport != null) ...[
                                    const SizedBox(width: 16),
                                    InkWell(
                                      onTap: () => widget.onReport!(
                                        widget.comment.fullname,
                                        widget.comment.subreddit,
                                      ),
                                      child: Icon(
                                        Icons.flag_outlined,
                                        size: 16,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                  if (widget.onEdit != null) ...[
                                    const SizedBox(width: 16),
                                    InkWell(
                                      onTap: () => widget.onEdit!(fullname),
                                      child: Icon(
                                        Icons.edit_outlined,
                                        size: 16,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                  if (widget.onDelete != null) ...[
                                    const SizedBox(width: 16),
                                    InkWell(
                                      onTap: () => widget.onDelete!(fullname),
                                      child: Icon(
                                        Icons.delete_outline,
                                        size: 16,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                  if (widget.onBlock != null) ...[
                                    const SizedBox(width: 16),
                                    InkWell(
                                      onTap: () => widget.onBlock!(
                                        widget.comment.author,
                                      ),
                                      child: Icon(
                                        Icons.block,
                                        size: 16,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                  ),
                ],
              ),
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
                  children: widget.comment.replies
                      .map(
                        (reply) => CommentTree(
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
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }
}
