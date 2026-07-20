import 'package:flutter/material.dart';

enum ErrorRetryVariant { fullScreen, banner }

class ErrorRetryWidget extends StatelessWidget {
  final String message;
  final String? retryLabel;
  final VoidCallback? onRetry;
  final Widget? icon;
  final ErrorRetryVariant variant;

  const ErrorRetryWidget({
    super.key,
    required this.message,
    this.retryLabel,
    this.onRetry,
    this.icon,
    this.variant = ErrorRetryVariant.fullScreen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return switch (variant) {
      ErrorRetryVariant.fullScreen => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon ??
                    Icon(Icons.error_outline,
                        size: 48, color: cs.onSurfaceVariant),
                const SizedBox(height: 12),
                Text(message,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center),
                if (onRetry != null) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(retryLabel ?? 'Retry'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ErrorRetryVariant.banner => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: cs.errorContainer,
            border: Border(bottom: BorderSide(color: cs.outlineVariant)),
          ),
          child: Row(
            children: [
              icon ?? Icon(Icons.error_outline, size: 20, color: cs.error),
              const SizedBox(width: 12),
              Expanded(child: Text(message, style: theme.textTheme.bodyMedium)),
              if (onRetry != null) ...[
                const SizedBox(width: 8),
                TextButton(
                    onPressed: onRetry, child: Text(retryLabel ?? 'Retry')),
              ],
            ],
          ),
        ),
    };
  }
}
