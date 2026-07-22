import 'package:flutter/material.dart';

import '../../domain/models/award_data.dart';
import '../utils/format_utils.dart';

const _maxVisibleAwards = 3;

/// Displays award data as a row of small award icons with counts.
///
/// When [awards] is empty, falls back to a simple count badge using
/// [awardCount]. Shows up to [_maxVisibleAwards] award icons inline,
/// then appends a "+N" overflow badge if more award types exist.
class AwardBadge extends StatelessWidget {
  final int awardCount;
  final List<AwardData> awards;

  const AwardBadge({
    super.key,
    required this.awardCount,
    this.awards = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (awards.isEmpty) {
      // Legacy fallback: simple count badge.
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          border: Border.all(color: cs.tertiary.withValues(alpha: 0.8)),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium_outlined,
                size: 11, color: cs.tertiary),
            const SizedBox(width: 2),
            Text(
              formatCount(awardCount),
              style: TextStyle(
                fontSize: 11,
                color: cs.tertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    // Rich multi-award display.
    final visible = awards.take(_maxVisibleAwards).toList();
    final overflow = awards.length - _maxVisibleAwards;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...visible.map((award) => Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Tooltip(
                message: '${award.name} ×${award.count}',
                child: award.iconUrl != null
                    ? Image.network(
                        award.iconUrl!,
                        width: 16,
                        height: 16,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.workspace_premium_outlined,
                          size: 14,
                          color: _colorOrTertiary(award.backgroundColor, cs),
                        ),
                      )
                    : Icon(
                        Icons.workspace_premium_outlined,
                        size: 14,
                        color: _colorOrTertiary(award.backgroundColor, cs),
                      ),
              ),
            )),
        if (overflow > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              border: Border.all(color: cs.tertiary.withValues(alpha: 0.6)),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              '+$overflow',
              style: TextStyle(
                fontSize: 10,
                color: cs.tertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Color _colorOrTertiary(String? hex, ColorScheme cs) {
    if (hex == null || hex.isEmpty) return cs.tertiary;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return cs.tertiary;
    }
  }
}
