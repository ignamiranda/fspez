import 'package:flutter/material.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border(bottom: BorderSide(color: Colors.amber.shade200)),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, size: 18, color: Colors.amber.shade800),
          const SizedBox(width: 8),
          Text(
            "You're offline. Showing cached content.",
            style: theme.textTheme.bodySmall
                ?.copyWith(color: Colors.amber.shade900),
          ),
        ],
      ),
    );
  }
}
