import 'package:flutter/material.dart';

class LabelValueRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool showZeroIfEmpty;

  const LabelValueRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.showZeroIfEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Text(label, style: theme.textTheme.bodyMedium),
        const Spacer(),
        Text(
          showZeroIfEmpty && value.isEmpty ? '0' : value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
