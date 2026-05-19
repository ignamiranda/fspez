import 'package:flutter/material.dart';
import '../../domain/models/comment.dart';
import '../../domain/enums/vote_direction.dart';

class CommentTree extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fullname = 't1_${comment.id}';
    final effectiveVote = voteOverrides[fullname] ?? comment.vote;
    final effectiveSaved = saveOverrides[fullname] ?? comment.isSaved;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (comment.depth > 0) ...[
                SizedBox(
                  width: comment.depth * 16.0,
                  child: CustomPaint(
                    painter: _DepthLinePainter(theme.colorScheme.outlineVariant),
                  ),
                ),
              ],
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'u/${comment.author}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (comment.isSubmitter) ...[
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
                          if (comment.isModerator) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.shield, size: 14, color: Colors.green[700]),
                          ],
                          const Spacer(),
                          Text(
                            '${comment.score} pts',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(comment.body, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          InkWell(
                            onTap: () => onVote?.call(fullname, VoteDirection.upvote),
                            child: Icon(
                              effectiveVote == VoteDirection.upvote
                                  ? Icons.arrow_upward
                                  : Icons.arrow_upward_outlined,
                              size: 16,
                              color: effectiveVote == VoteDirection.upvote
                                  ? Colors.orange
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: () => onVote?.call(fullname, VoteDirection.downvote),
                            child: Icon(
                              effectiveVote == VoteDirection.downvote
                                  ? Icons.arrow_downward
                                  : Icons.arrow_downward_outlined,
                              size: 16,
                              color: effectiveVote == VoteDirection.downvote
                                  ? Colors.blue
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 16),
                          if (onReply != null)
                            InkWell(
                              onTap: () => onReply!(comment.id, comment.author),
                              child: const Icon(
                                Icons.reply_outlined,
                                size: 16,
                              ),
                            )
                          else
                            const Icon(
                              Icons.reply_outlined,
                              size: 16,
                            ),
                          const SizedBox(width: 16),
                          InkWell(
                            onTap: () => onSave?.call(fullname),
                            child: Icon(
                              effectiveSaved
                                  ? Icons.bookmark
                                  : Icons.bookmark_outline,
                              size: 16,
                              color: effectiveSaved
                                  ? Colors.amber
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!comment.isCollapsed)
          ...comment.replies.map((reply) => CommentTree(
            comment: reply,
            voteOverrides: voteOverrides,
            onVote: onVote,
            saveOverrides: saveOverrides,
            onSave: onSave,
            onReply: onReply,
          )),
      ],
    );
  }
}

class _DepthLinePainter extends CustomPainter {
  final Color color;

  _DepthLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width - 8, 0),
      Offset(size.width - 8, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
