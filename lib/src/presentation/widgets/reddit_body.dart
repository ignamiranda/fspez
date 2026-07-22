import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/reddit_markdown.dart';
import '../utils/spoiler_syntax.dart';
import '../screens/user_profile_screen.dart';
import '../screens/subreddit_feed_screen.dart';

/// Renders Reddit markdown body text with consistent styling.
///
/// Handles Giphy embeds, heading markers, spoiler syntax, user/subreddit
/// mentions, and other Reddit-specific markdown via [normalizeRedditMarkdown]
/// before passing to [MarkdownBody].
class RedditBody extends StatelessWidget {
  final String data;

  const RedditBody(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final styleSheet = MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
      a: TextStyle(
        color: colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
      blockquoteDecoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.48),
        border: Border(
          left: BorderSide(
            color: colorScheme.primary,
            width: 4,
          ),
        ),
      ),
      code: theme.textTheme.bodyMedium?.copyWith(
        backgroundColor: colorScheme.surfaceContainerHighest,
        fontFamily: 'monospace',
      ),
      codeblockDecoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
    );

    return MarkdownBody(
      data: normalizeRedditMarkdown(data),
      styleSheet: styleSheet,
      inlineSyntaxes: [
        SpoilerInlineSyntax(),
      ],
      builders: {
        'spoiler': SpoilerElementBuilder(),
      },
      onTapLink: (text, href, title) {
        final url = href ?? text;
        if (url.isEmpty) return;

        if (url.startsWith(mentionUrlPrefix)) {
          final parts = url.substring(mentionUrlPrefix.length).split('/');
          if (parts.length >= 2) {
            final type = parts[0];
            final target = parts[1];
            if (type == 'user') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => UserProfileScreen(username: target),
                ),
              );
            } else if (type == 'subreddit') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SubredditFeedScreen(subredditName: target),
                ),
              );
            }
          }
        } else {
          launchUrl(Uri.parse(url));
        }
      },
    );
  }
}
