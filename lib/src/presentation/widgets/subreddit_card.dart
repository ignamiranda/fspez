import 'package:flutter/material.dart';
import '../../domain/models/subreddit.dart';
import '../utils/format_utils.dart';

class SubredditCard extends StatelessWidget {
  final Subreddit subreddit;
  final VoidCallback? onTap;

  const SubredditCard({
    super.key,
    required this.subreddit,
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 48,
                height: 48,
                child: _buildIcon(theme, cs),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'r/${subreddit.name}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subreddit.subscriberCount > 0)
                    Text(
                      '${formatCount(subreddit.subscriberCount)} members',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  if (subreddit.description != null &&
                      subreddit.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subreddit.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            if (subreddit.isNsfw)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.error),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'NSFW',
                  style: TextStyle(
                    fontSize: 10,
                    color: cs.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(ThemeData theme, ColorScheme cs) {
    final iconUrl = subreddit.iconUrl;
    if (iconUrl != null && iconUrl.isNotEmpty) {
      return Image.network(
        iconUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _defaultIcon(theme, cs),
      );
    }
    return _defaultIcon(theme, cs);
  }

  Widget _defaultIcon(ThemeData theme, ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Icon(
        Icons.reddit,
        size: 28,
        color: cs.onSurfaceVariant,
      ),
    );
  }
}
