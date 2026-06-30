import 'package:flutter/material.dart';

/// A tappable media preview tile used in the feed for images and galleries.
class FeedMediaTile extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onTap;
  final String? badgeText;
  final IconData? badgeIcon;
  final double maxHeight;

  const FeedMediaTile({
    super.key,
    required this.imageUrl,
    required this.onTap,
    this.badgeText,
    this.badgeIcon,
    this.maxHeight = 240,
  });

  @override
  Widget build(BuildContext context) {
    final child = ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.network(
              imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
            if (badgeText != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (badgeIcon != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(badgeIcon, color: Colors.white, size: 14),
                        ),
                      Text(
                        badgeText!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GestureDetector(onTap: onTap, child: child),
    );
  }
}
