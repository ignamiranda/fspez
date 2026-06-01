import 'package:flutter/material.dart';

import '../utils/format_utils.dart';

class AwardBadge extends StatelessWidget {
  final int awardCount;

  const AwardBadge({super.key, required this.awardCount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: cs.tertiary.withOpacity(0.8)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_outlined, size: 11, color: cs.tertiary),
          const SizedBox(width: 2),
          Text(
            formatCount(awardCount),
            style: TextStyle(
              fontSize: 9,
              color: cs.tertiary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
