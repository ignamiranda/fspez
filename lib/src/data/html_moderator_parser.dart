import 'shreddit_json_extractor.dart';

class HtmlModeratorParser {
  List<String> parseModeratedSubreddits(String html) {
    final extracted = ShredditJsonExtractor.extract(html);
    final pageProps = _pageProps(extracted);

    final rawSubs = pageProps['moderatedSubreddits'] as List<dynamic>? ??
        pageProps['subreddits'] as List<dynamic>? ??
        [];

    final names = rawSubs
        .whereType<Map<String, dynamic>>()
        .map((raw) {
          return raw['displayName'] as String? ??
              raw['display_name'] as String? ??
              raw['name'] as String? ??
              '';
        })
        .where((name) => name.isNotEmpty)
        .toList();

    return names;
  }

  Map<String, dynamic> _pageProps(Map<String, dynamic> extracted) {
    final props = extracted['props'] as Map<String, dynamic>?;
    if (props == null) return extracted;
    return props['pageProps'] as Map<String, dynamic>? ?? extracted;
  }
}
