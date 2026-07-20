import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown/markdown.dart' as md;

import '../../data/app_settings.dart';
import 'reddit_markdown.dart';

/// Pattern string for matching `\uFFFF...\uFFFE` spoiler delimiters.
///
/// Uses `[\s\S]*?` instead of `.*` because [InlineSyntax] creates regexes
/// without `dotAll`, so `.` would not match newlines. This pattern ensures
/// spoilers spanning multiple lines are matched correctly.
const _spoilerPatternString = '${spoilerStart}[\\s\\S]*?$spoilerEnd';

/// Custom inline syntax that matches pre-processed spoiler markers inserted
/// by [normalizeRedditMarkdown].
///
/// The pattern matches `\uFFFF...\uFFFE` pairs which are Unicode non-characters
/// guaranteed to never appear in valid Reddit text content.
class SpoilerInlineSyntax extends md.InlineSyntax {
  SpoilerInlineSyntax() : super(
    _spoilerPatternString,
    startCharacter: 0xFFFF, // \uFFFF
  );

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    // Extract the spoiler content, stripping the delimiters.
    // match.group(0) is the full match including delimiters.
    // The content is everything between the start and end delimiter.
    final fullMatch = match.group(0)!;
    final content = fullMatch.substring(
      spoilerStart.length,
      fullMatch.length - spoilerEnd.length,
    );
    // Use Element(tag, children) not Element.withTag() — the latter creates
    // an unmodifiable empty children list.
    parser.addNode(md.Element('spoiler', [md.Text(content)]));
    return true;
  }
}

/// Builds a tap-to-reveal spoiler widget for the `spoiler` tag.
class SpoilerElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final text = element.children
        ?.whereType<md.Text>()
        .map((t) => t.text)
        .join();
    if (text == null || text.isEmpty) return null;

    // Respect the user's spoiler blur setting.
    final spoilerBlur = _readSpoilerBlur(context);

    return _SpoilerWidget(text: text, initiallyHidden: spoilerBlur);
  }

  bool _readSpoilerBlur(BuildContext context) {
    try {
      return ProviderScope.containerOf(context, listen: false)
          .read(appSettingsProvider)
          .spoilerBlur;
    } catch (_) {
      // Default to hidden if provider isn't available (e.g. in tests).
      return true;
    }
  }
}

/// A tap-to-reveal inline spoiler widget.
///
/// When [initiallyHidden] is true (default), the text is rendered as a black
/// bar. Tapping reveals it.
class _SpoilerWidget extends StatefulWidget {
  final String text;
  final bool initiallyHidden;

  const _SpoilerWidget({
    required this.text,
    this.initiallyHidden = true,
  });

  @override
  State<_SpoilerWidget> createState() => _SpoilerWidgetState();
}

class _SpoilerWidgetState extends State<_SpoilerWidget> {
  late bool _revealed;

  @override
  void initState() {
    super.initState();
    _revealed = !widget.initiallyHidden;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_revealed) {
      return Text(
        widget.text,
        style: TextStyle(
          backgroundColor: cs.tertiaryContainer.withValues(alpha: 0.3),
        ),
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _revealed = true),
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: Text(
          widget.text,
          style: const TextStyle(color: Colors.transparent),
        ),
      ),
    );
  }
}
