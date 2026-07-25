import 'dart:convert';

class ShredditJsonExtractor {
  static Map<String, dynamic> extract(String html) {
    final patterns = [
      _nextDataPattern,
      _initialStatePattern,
      _shredditStatePattern,
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(html);
      if (match != null) {
        final jsonStr = match.group(1);
        if (jsonStr != null && jsonStr.isNotEmpty) {
          try {
            final decoded = jsonDecode(jsonStr);
            if (decoded is Map<String, dynamic>) return decoded;
          } catch (_) {}
        }
      }
    }

    return {};
  }

  static String? extractRaw(String html) {
    final patterns = [
      _nextDataPattern,
      _initialStatePattern,
      _shredditStatePattern,
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(html);
      if (match != null) {
        return match.group(1);
      }
    }

    return null;
  }

  static final _nextDataPattern = RegExp(
    r'<script id="__NEXT_DATA__"[^>]*type="application/json"[^>]*>'
    r'(.*?)'
    r'</script>',
    caseSensitive: false,
    dotAll: true,
  );

  static final _initialStatePattern = RegExp(
    r'<script[^>]*>window\.__INITIAL_STATE__\s*=\s*'
    r'(.*?)'
    r';\s*</script>',
    caseSensitive: false,
    dotAll: true,
  );

  static final _shredditStatePattern = RegExp(
    r'<script id="data"[^>]*>window\.__r\s*=\s*'
    r'(.*?)'
    r';\s*</script>',
    caseSensitive: false,
    dotAll: true,
  );
}
