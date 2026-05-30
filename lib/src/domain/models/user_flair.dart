import 'package:equatable/equatable.dart';

/// Community-specific user flair attached to a post or comment author.
///
/// Reddit exposes flair via `author_flair_text` plus optional color fields
/// (`author_flair_background_color`, `author_flair_text_color`) and a richtext
/// array (`author_flair_richtext`). This model holds the resolved display text
/// and colors; richtext emoji/text parts are flattened into [text].
class UserFlair with EquatableMixin {
  final String text;

  /// Hex color string (e.g. `#ff4500`) for the chip background, or null.
  final String? backgroundColor;

  /// Either `light` or `dark` per Reddit's API, or a hex string. Null when
  /// unspecified.
  final String? textColor;

  const UserFlair({
    required this.text,
    this.backgroundColor,
    this.textColor,
  });

  /// Builds a [UserFlair] from raw Reddit API author-flair fields.
  ///
  /// Prefers flattening `author_flair_richtext` parts (joining emoji `a` and
  /// text `t` entries) and falls back to `author_flair_text`. Returns null when
  /// there is no usable flair text.
  static UserFlair? fromApi({
    String? text,
    List<dynamic>? richtext,
    String? backgroundColor,
    String? textColor,
  }) {
    String resolved = '';
    if (richtext != null && richtext.isNotEmpty) {
      final buffer = StringBuffer();
      for (final part in richtext) {
        if (part is! Map<String, dynamic>) continue;
        final type = part['e'] as String?;
        if (type == 'text') {
          buffer.write(part['t'] as String? ?? '');
        } else if (type == 'emoji') {
          buffer.write(part['a'] as String? ?? '');
        }
      }
      resolved = buffer.toString().trim();
    }
    if (resolved.isEmpty) {
      resolved = (text ?? '').trim();
    }
    if (resolved.isEmpty) return null;

    String? bg = backgroundColor;
    if (bg != null && (bg.isEmpty || bg == 'transparent')) bg = null;

    return UserFlair(
      text: resolved,
      backgroundColor: bg,
      textColor: (textColor != null && textColor.isEmpty) ? null : textColor,
    );
  }

  @override
  List<Object?> get props => [text, backgroundColor, textColor];
}
