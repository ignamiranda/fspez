import 'dart:ui';

import 'package:flutter/material.dart';

class SensitiveMediaOverlay extends StatelessWidget {
  final bool isNsfw;
  final bool isSpoiler;
  final VoidCallback onReveal;
  final Widget child;

  const SensitiveMediaOverlay({
    super.key,
    required this.isNsfw,
    required this.isSpoiler,
    required this.onReveal,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = <String>[if (isNsfw) 'NSFW', if (isSpoiler) 'Spoiler'];

    return GestureDetector(
      onTap: onReveal,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.passthrough,
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: child,
            ),
            Container(color: Colors.black54),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: labels.map((label) {
                    final color = label == 'NSFW'
                        ? theme.colorScheme.error
                        : theme.colorScheme.tertiary;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: color),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to reveal',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
