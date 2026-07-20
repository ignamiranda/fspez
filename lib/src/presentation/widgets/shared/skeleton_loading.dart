import 'package:flutter/material.dart';

class SkeletonLoading extends StatelessWidget {
  final int itemCount;

  const SkeletonLoading({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => Divider(height: 1, color: cs.outlineVariant),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ShimmerBox(width: 36, height: 36, cs: cs),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBox(width: 120, height: 12, cs: cs),
                    const SizedBox(height: 8),
                    _ShimmerBox(width: double.infinity, height: 14, cs: cs),
                    const SizedBox(height: 4),
                    _ShimmerBox(width: 200, height: 14, cs: cs),
                    const SizedBox(height: 8),
                    _ShimmerBox(width: 80, height: 10, cs: cs),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final ColorScheme cs;

  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width.isInfinite ? null : width,
      height: height,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
