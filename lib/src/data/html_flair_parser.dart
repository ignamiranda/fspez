import '../domain/models/flair_option.dart';
import 'shreddit_json_extractor.dart';

int? _parseFlairColor(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  if (raw == 'light' || raw == 'dark') return null;
  var hex = raw;
  if (hex.startsWith('#')) hex = hex.substring(1);
  if (hex.length == 6) hex = 'FF$hex';
  return int.tryParse(hex, radix: 16);
}

class HtmlFlairParser {
  List<FlairOption> parseFlairOptions(String html) {
    final extracted = ShredditJsonExtractor.extract(html);
    final pageProps = _pageProps(extracted);

    final rawFlairs = pageProps['flairOptions'] as List<dynamic>? ??
        pageProps['postFlairs'] as List<dynamic>? ??
        [];

    return rawFlairs.whereType<Map<String, dynamic>>().map((raw) {
      final text = _str(raw, 'text') ?? _str(raw, 'flair_text') ?? '';
      return FlairOption(
        flairTemplateId: _str(raw, 'flairTemplateId') ??
            _str(raw, 'flair_template_id') ??
            '',
        text: text,
        isEditable: (raw['textEditable'] as bool?) ??
            (raw['text_editable'] as bool?) ??
            (raw['isEditable'] as bool?) ??
            false,
        backgroundColor: _parseFlairColor(
          _str(raw, 'backgroundColor') ??
              _str(raw, 'flairBackgroundColor') ??
              _str(raw, 'flair_background_color'),
        ),
        textColor: _parseFlairColor(
          _str(raw, 'textColor') ??
              _str(raw, 'flairTextColor') ??
              _str(raw, 'flair_text_color'),
        ),
        cssClass: _str(raw, 'cssClass') ?? _str(raw, 'flair_css_class'),
        richtext: raw['richtext'] as List<dynamic>? ??
            raw['flair_richtext'] as List<dynamic>?,
      );
    }).toList();
  }

  Map<String, dynamic> _pageProps(Map<String, dynamic> extracted) {
    final props = extracted['props'] as Map<String, dynamic>?;
    if (props == null) return extracted;
    return props['pageProps'] as Map<String, dynamic>? ?? extracted;
  }

  String? _str(Map<String, dynamic> map, String key) => map[key] as String?;
}
