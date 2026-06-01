class RedditAwardHtmlParser {
  static final _tagPattern = RegExp(
    r'<(shreddit-post|shreddit-comment)\b([^>]*)>',
    caseSensitive: false,
  );

  static final _attributePattern = RegExp(r'([a-zA-Z0-9_-]+)="([^"]*)"');
  static final _partialTagPattern = RegExp(
    r'<faceplate-partial\b([^>]*)>',
    caseSensitive: false,
  );

  static Map<String, int> parseAwardCounts(String html) {
    final counts = <String, int>{};

    for (final match in _tagPattern.allMatches(html)) {
      final tagName = match.group(1)?.toLowerCase();
      final attrs = _parseAttributes(match.group(2) ?? '');
      final count = _parseCount(attrs['award-count']);
      if (tagName == null || count == null || count <= 0) continue;

      final id =
          _normalizeIdentifier(tagName, _identifierFromAttributes(attrs));
      if (id == null || id.isEmpty) continue;

      counts.update(
        id,
        (existing) => existing >= count ? existing : count,
        ifAbsent: () => count,
      );
    }

    return counts;
  }

  static String? extractCommentsPartialPath(String html) {
    for (final match in _partialTagPattern.allMatches(html)) {
      final attrs = _parseAttributes(match.group(1) ?? '');
      final name = attrs['name'];
      final src = attrs['src'];
      if (name != null &&
          name.startsWith('TopComments') &&
          src != null &&
          src.isNotEmpty) {
        return src;
      }
    }
    return null;
  }

  static Map<String, String> _parseAttributes(String rawAttributes) {
    final attrs = <String, String>{};
    for (final match in _attributePattern.allMatches(rawAttributes)) {
      final name = match.group(1);
      final value = match.group(2);
      if (name != null && value != null) {
        attrs[name.toLowerCase()] = value;
      }
    }
    return attrs;
  }

  static String? _identifierFromAttributes(Map<String, String> attrs) {
    for (final key in const [
      'data-fullname',
      'thing-id',
      'comment-id',
      'post-id',
      'id',
    ]) {
      final value = attrs[key];
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  static String? _normalizeIdentifier(String tagName, String? identifier) {
    if (identifier == null || identifier.isEmpty) return null;
    if (identifier.startsWith('t1_') || identifier.startsWith('t3_')) {
      return identifier;
    }
    if (tagName == 'shreddit-comment') return 't1_$identifier';
    if (tagName == 'shreddit-post') return 't3_$identifier';
    return identifier;
  }

  static int? _parseCount(String? rawCount) {
    if (rawCount == null || rawCount.isEmpty) return null;
    return int.tryParse(rawCount);
  }
}
