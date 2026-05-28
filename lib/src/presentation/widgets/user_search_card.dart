import 'package:flutter/material.dart';
import '../../domain/models/search_user.dart';
import '../utils/format_utils.dart';

class UserSearchCard extends StatelessWidget {
  final SearchUser user;
  final VoidCallback? onTap;

  const UserSearchCard({
    super.key,
    required this.user,
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
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                width: 48,
                height: 48,
                child: _buildAvatar(cs),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'u/${user.name}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (user.isGold)
                        Icon(Icons.auto_awesome, size: 14, color: cs.tertiary),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatCount(user.linkKarma)} link karma · ${formatCount(user.commentKarma)} comment karma',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (user.isMod)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.secondary),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'MOD',
                  style: TextStyle(
                    fontSize: 10,
                    color: cs.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(ColorScheme cs) {
    final iconUrl = user.iconImg;
    if (iconUrl != null && iconUrl.isNotEmpty) {
      return Image.network(
        iconUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _defaultAvatar(cs),
      );
    }
    return _defaultAvatar(cs);
  }

  Widget _defaultAvatar(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Icon(
        Icons.person,
        size: 28,
        color: cs.onSurfaceVariant,
      ),
    );
  }
}
