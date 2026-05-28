String normalizeRedditMarkdown(String markdown) {
  return markdown.splitMapJoin(
    '\n',
    onNonMatch: _normalizeRedditMarkdownLine,
  );
}

String _normalizeRedditMarkdownLine(String line) {
  return line.replaceFirstMapped(
    RegExp(r'^( {0,3}#{1,6})(?=[^\s#])'),
    (match) => '${match.group(1)} ',
  );
}
