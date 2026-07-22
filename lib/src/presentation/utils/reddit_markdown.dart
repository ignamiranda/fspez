/// Regex matching Reddit's spoiler syntax `>!spoiler!<`, which may span
/// multiple lines.
final _spoilerPattern = RegExp(
  r'>!(.*?)!<',
  dotAll: true,
);

/// Pattern matching Reddit's Giphy shorthand: ![gif](giphy|ID) or
/// ![gif](giphy|ID|format)
final _giphyPattern = RegExp(
  r'!\[gif\]\(giphy\|([a-zA-Z0-9_-]+)(?:\|([a-zA-Z0-9_]+))?\)',
);

/// Pattern matching `u/username` mentions. Avoids matching inside markdown
/// link brackets `[...]`, after `/`, or as part of a larger word.
final _userMentionPattern = RegExp(
  r'(?<![\[/\w])u/([a-zA-Z0-9_-]+)(?!\w)',
);

/// Pattern matching `r/subreddit` mentions. Same guard conditions.
final _subredditMentionPattern = RegExp(
  r'(?<![\[/\w])r/([a-zA-Z0-9_]+)(?!\w)',
);

/// Unicode non-characters used as spoiler delimiters. These are guaranteed
/// to never appear in valid Reddit text content per the Unicode spec.
const spoilerStart = '\uFFFF';
const spoilerEnd = '\uFFFE';

/// Custom URL scheme used for [normalizeRedditMarkdown] to encode mentions
/// as navigable links. The [RedditBody] widget handles this scheme in its
/// [MarkdownBody.onTapLink] callback.
const mentionUrlPrefix = 'fspez-mention://';

/// Normalizes Reddit-flavored markdown for rendering via flutter_markdown_plus.
///
/// Handles:
/// - Spoiler syntax (`>!spoiler!<`) → wrapped in non-character delimiters
/// - Giphy embeds (`![gif](giphy|ID)`) → expanded to full URLs
/// - Heading markers (`##text`) → space after `#`
/// - User/subreddit mentions (`u/name`, `r/name`) → markdown links
String normalizeRedditMarkdown(String markdown) {
  // Pre-process spoiler syntax before line-by-line processing to prevent
  // the blockquote parser from intercepting `>` at line start.
  markdown = markdown.replaceAllMapped(
    _spoilerPattern,
    (match) => '$spoilerStart${match.group(1)}$spoilerEnd',
  );

  return markdown.splitMapJoin(
    '\n',
    onNonMatch: _normalizeRedditMarkdownLine,
  );
}

String _normalizeRedditMarkdownLine(String line) {
  return line
      .replaceFirstMapped(
        RegExp(r'^( {0,3}#{1,6})(?=[^\s#])'),
        (match) => '${match.group(1)} ',
      )
      .replaceAllMapped(
        _giphyPattern,
        (match) =>
            '![gif](https://media.giphy.com/media/${match.group(1)}/giphy.gif)',
      )
      .replaceAllMapped(
        _userMentionPattern,
        (match) =>
            '[${match.group(0)}](${mentionUrlPrefix}user/${match.group(1)})',
      )
      .replaceAllMapped(
        _subredditMentionPattern,
        (match) =>
            '[${match.group(0)}](${mentionUrlPrefix}subreddit/${match.group(1)})',
      );
}
