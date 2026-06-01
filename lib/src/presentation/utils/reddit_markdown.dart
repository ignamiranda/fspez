/// Pattern matching Reddit's Giphy shorthand: ![gif](giphy|ID) or
/// ![gif](giphy|ID|format)
final _giphyPattern = RegExp(
  r'!\[gif\]\(giphy\|([a-zA-Z0-9_-]+)(?:\|([a-zA-Z0-9_]+))?\)',
);

String normalizeRedditMarkdown(String markdown) {
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
      );
}
