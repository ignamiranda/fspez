import 'package:flutter/material.dart';

class CommentListItem extends StatelessWidget {
  final String? subreddit;
  final String? author;
  final String? title;
  final String body;
  final int score;
  final int? commentCount;
  final String? timestamp;
  final VoidCallback? onTap;

  const CommentListItem({
    super.key,
    this.subreddit,
    this.author,
    this.title,
    required this.body,
    required this.score,
    this.commentCount,
    this.timestamp,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: cs.outlineVariant, width: 0.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subreddit != null || author != null || timestamp != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    if (subreddit != null)
                      Text(
                        'r/${subreddit!}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
                    if (subreddit != null &&
                        (author != null || timestamp != null))
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text('·'),
                      ),
                    if (author != null)
                      Text(
                        'u/${author!}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    if (author != null && timestamp != null)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text('·'),
                      ),
                    if (timestamp != null)
                      Text(
                        timestamp!,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            if (title != null && title!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  title!,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (body.isNotEmpty)
              Text(
                body,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.arrow_upward, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 2),
                Text(
                  '$score',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                if (commentCount != null) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 14,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${commentCount!}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
