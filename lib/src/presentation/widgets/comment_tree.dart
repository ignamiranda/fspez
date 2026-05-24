import 'package:flutter/material.dart';
import '../../domain/models/comment.dart';
import '../../domain/enums/vote_direction.dart';

class CommentTree extends StatefulWidget {
  final Comment comment;
  final Map<String, VoteDirection> voteOverrides;
  final void Function(String fullname, VoteDirection direction)? onVote;
  final Map<String, bool> saveOverrides;
  final void Function(String fullname)? onSave;
  final void Function(String commentId, String author)? onReply;

  const CommentTree({
    super.key,
    required this.comment,
    this.voteOverrides = const {},
    this.onVote,
    this.saveOverrides = const {},
    this.onSave,
    this.onReply,
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
    final effectiveSaved = widget.saveOverrides[fullname] ?? widget.comment.isSaved;

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
              padding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'u/${widget.comment.author}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (widget.comment.isSubmitter) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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
                        Icon(Icons.shield, size: 14, color: theme.colorScheme.tertiary),
                      ],
                      const Spacer(),
                      if (_isCollapsed)
                        Icon(Icons.unfold_more, size: 14,
                            color: theme.colorScheme.onSurfaceVariant),
                      Text(
                        '${widget.comment.score} pts',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
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
                              Text(widget.comment.body, style: theme.textTheme.bodyMedium),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  InkWell(
                                    onTap: () => widget.onVote?.call(fullname, VoteDirection.upvote),
                                    child: Icon(
                                      effectiveVote == VoteDirection.upvote
                                          ? Icons.arrow_upward
                                          : Icons.arrow_upward_outlined,
                                      size: 16,
                                      color: effectiveVote == VoteDirection.upvote
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  InkWell(
                                    onTap: () => widget.onVote?.call(fullname, VoteDirection.downvote),
                                    child: Icon(
                                      effectiveVote == VoteDirection.downvote
                                          ? Icons.arrow_downward
                                          : Icons.arrow_downward_outlined,
                                      size: 16,
                                      color: effectiveVote == VoteDirection.downvote
                                          ? theme.colorScheme.secondary
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  if (widget.onReply != null)
                                    InkWell(
                                      onTap: () => widget.onReply!(widget.comment.id, widget.comment.author),
                                      child: Icon(
                                        Icons.reply_outlined,
                                        size: 16,
                                        color: theme.colorScheme.onSurfaceVariant,
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
                  children: widget.comment.replies.map((reply) => CommentTree(
                    comment: reply,
                    voteOverrides: widget.voteOverrides,
                    onVote: widget.onVote,
                    saveOverrides: widget.saveOverrides,
                    onSave: widget.onSave,
                    onReply: widget.onReply,
                  )).toList(),
                ),
        ),
      ],
    );
  }
}
