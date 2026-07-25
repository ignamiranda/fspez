import 'html_parser_utils.dart';
import 'shreddit_json_extractor.dart';

class HtmlModeratorParser {
  List<String> parseModeratedSubreddits(String html) {
    final extracted = ShredditJsonExtractor.extract(html);
    final pp = pageProps(extracted);

    final rawSubs = pp['moderatedSubreddits'] as List<dynamic>? ??
        pp['subreddits'] as List<dynamic>? ??
        [];

    return rawSubs
        .whereType<Map<String, dynamic>>()
        .map((raw) {
          return raw['displayName'] as String? ??
              raw['display_name'] as String? ??
              raw['name'] as String? ??
              '';
        })
        .where((name) => name.isNotEmpty)
        .toList();
  }
}
