import 'package:flutter/material.dart';
import '../../domain/models/subreddit.dart';

class SubredditIcon extends StatelessWidget {
  final Subreddit subreddit;
  final double size;

  const SubredditIcon({
    super.key,
    required this.subreddit,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconUrl = subreddit.iconUrl;
    final hasIcon = iconUrl != null && iconUrl.isNotEmpty;

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: hasIcon
            ? Image.network(
                iconUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _LetterAvatar(name: subreddit.name, theme: theme),
              )
            : _LetterAvatar(name: subreddit.name, theme: theme),
      ),
    );
  }
}

class _LetterAvatar extends StatelessWidget {
  final String name;
  final ThemeData theme;

  const _LetterAvatar({required this.name, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'r',
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
