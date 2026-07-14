import 'package:flutter/material.dart';
import '../../domain/models/post.dart';

class PostTitleWithThumbnail extends StatelessWidget {
  final Post post;
  final String? thumbnailUrl;
  final ThemeData theme;
  final bool isCompact;

  const PostTitleWithThumbnail({
    super.key,
    required this.post,
    required this.thumbnailUrl,
    required this.theme,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final thumbnailSize = isCompact ? 48.0 : 56.0;
    final thumbnailPadding = isCompact ? 2.0 : 3.0;
    if (isCompact && thumbnailUrl != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PostThumbnailFrame(
            theme: theme,
            thumbnailUrl: thumbnailUrl!,
            size: thumbnailSize,
            padding: thumbnailPadding,
            iconSize: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                post.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            post.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (thumbnailUrl != null)
          Padding(
            padding: EdgeInsets.only(left: 8, top: isCompact ? 1 : 0),
            child: PostThumbnailFrame(
              theme: theme,
              thumbnailUrl: thumbnailUrl!,
              size: thumbnailSize,
              padding: thumbnailPadding,
              iconSize: isCompact ? 18 : 16,
            ),
          ),
      ],
    );
  }
}

class PostThumbnailFrame extends StatelessWidget {
  final ThemeData theme;
  final String thumbnailUrl;
  final double size;
  final double padding;
  final double iconSize;

  const PostThumbnailFrame({
    super.key,
    required this.theme,
    required this.thumbnailUrl,
    required this.size,
    required this.padding,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          thumbnailUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.link,
              size: iconSize,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
