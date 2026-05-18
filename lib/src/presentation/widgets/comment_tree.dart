import 'package:flutter/material.dart';
import '../../domain/models/comment.dart';
import '../../domain/enums/vote_direction.dart';

class CommentTree extends StatelessWidget {
  final Comment comment;

  const CommentTree({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                          Icon(
                            comment.vote == VoteDirection.upvote
                                ? Icons.arrow_upward
                                : Icons.arrow_upward_outlined,
                            size: 16,
                            color: comment.vote == VoteDirection.upvote
                                ? Colors.orange
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            comment.vote == VoteDirection.downvote
                                ? Icons.arrow_downward
                                : Icons.arrow_downward_outlined,
                            size: 16,
                            color: comment.vote == VoteDirection.downvote
                                ? Colors.blue
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.reply_outlined,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            comment.isSaved ? Icons.bookmark : Icons.bookmark_outline,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
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
          ...comment.replies.map((reply) => CommentTree(comment: reply)),
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
