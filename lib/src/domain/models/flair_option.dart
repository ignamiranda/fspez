import 'package:equatable/equatable.dart';

/// A post flair template from a subreddit, used for flair selection on submit.
///
/// Maps to Reddit's `flair_template` objects returned by the post_flairs API.
/// Colors are parsed to int for direct use as Material Color values.
class FlairOption with EquatableMixin {
  final String flairTemplateId;
  final String text;
  final int? backgroundColor;
  final int? textColor;
  final String? cssClass;
  final List<dynamic>? richtext;
  final bool isEditable;

  const FlairOption({
    required this.flairTemplateId,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.cssClass,
    this.richtext,
    this.isEditable = false,
  });

  factory FlairOption.fromJson(Map<String, dynamic> json) {
    return FlairOption(
      flairTemplateId: json['flair_template_id'] as String? ?? '',
      text: json['flair_text'] as String? ?? '',
      backgroundColor: _parseColor(json['flair_background_color'] as String?),
      textColor: _parseColor(json['flair_text_color'] as String?),
      cssClass: json['flair_css_class'] as String?,
      richtext: json['flair_richtext'] as List<dynamic>?,
      isEditable: json['text_editable'] as bool? ?? false,
    );
  }

  /// Parses a hex color string (`#RRGGBB` or `#AARRGGBB`) to ARGB int.
  ///
  /// Returns null for null/empty input or keyword values (`light`, `dark`).
  static int? _parseColor(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw == 'light' || raw == 'dark') return null;
    var hex = raw;
    if (hex.startsWith('#')) hex = hex.substring(1);
    if (hex.length == 6) hex = 'FF$hex';
    return int.tryParse(hex, radix: 16);
  }

  /// The resolved text, flattening richtext parts when [text] is empty.
  String get displayText {
    if (text.isNotEmpty) return text;
    if (richtext == null || richtext!.isEmpty) return '';
    final buffer = StringBuffer();
    for (final part in richtext!) {
      if (part is! Map<String, dynamic>) continue;
      final type = part['e'] as String?;
      if (type == 'text') {
        buffer.write(part['t'] as String? ?? '');
      } else if (type == 'emoji') {
        buffer.write(part['a'] as String? ?? '');
      }
    }
    return buffer.toString().trim();
  }

  @override
  List<Object?> get props => [
    flairTemplateId,
    text,
    backgroundColor,
    textColor,
    cssClass,
    richtext,
    isEditable,
  ];
}
