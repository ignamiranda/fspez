import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/presentation/utils/reddit_markdown.dart';

void main() {
  group('normalizeRedditMarkdown', () {
    test('adds missing space after reddit-style heading markers', () {
      expect(normalizeRedditMarkdown('####WELCOME'), '#### WELCOME');
      expect(normalizeRedditMarkdown('#Title'), '# Title');
    });

    test('preserves headings that already have spaces', () {
      expect(normalizeRedditMarkdown('## Welcome'), '## Welcome');
    });

    test('normalizes heading markers on each line', () {
      expect(
        normalizeRedditMarkdown('intro\n###Rules\nbody'),
        'intro\n### Rules\nbody',
      );
    });

    test('does not treat seven hashes as a heading', () {
      expect(normalizeRedditMarkdown('#######LOUD'), '#######LOUD');
    });

    group('giphy embeds', () {
      test('rewrites giphy shorthand to a real Giphy URL', () {
        final result =
            normalizeRedditMarkdown('![gif](giphy|z1QODTjvAwtXzf1q0M|downsized)');
        expect(
          result,
          '![gif](https://media.giphy.com/media/z1QODTjvAwtXzf1q0M/giphy.gif)',
        );
      });

      test('rewrites giphy shorthand without a format segment', () {
        final result =
            normalizeRedditMarkdown('![gif](giphy|fH0ukveQzPbrikcXO8)');
        expect(
          result,
          '![gif](https://media.giphy.com/media/fH0ukveQzPbrikcXO8/giphy.gif)',
        );
      });

      test('rewrites giphy with different format', () {
        final result =
            normalizeRedditMarkdown('![gif](giphy|abc123|fixed_height)');
        expect(
          result,
          '![gif](https://media.giphy.com/media/abc123/giphy.gif)',
        );
      });

      test('rewrites multiple giphy embeds on the same line', () {
        final result = normalizeRedditMarkdown(
          'First ![gif](giphy|aaa|downsized) and second ![gif](giphy|bbb|original)',
        );
        expect(
          result,
          'First ![gif](https://media.giphy.com/media/aaa/giphy.gif) '
              'and second ![gif](https://media.giphy.com/media/bbb/giphy.gif)',
        );
      });

      test('rewrites giphy on one line and preserves heading on another', () {
        final result =
            normalizeRedditMarkdown('###Title\n![gif](giphy|xYz|downsized)');
        expect(
          result,
          '### Title\n![gif](https://media.giphy.com/media/xYz/giphy.gif)',
        );
      });

      test('handles giphy IDs with hyphens and underscores', () {
        final result =
            normalizeRedditMarkdown('![gif](giphy|abc-123_def|downsized)');
        expect(
          result,
          '![gif](https://media.giphy.com/media/abc-123_def/giphy.gif)',
        );
      });

      test('does nothing to plain text without giphy shorthand', () {
        expect(normalizeRedditMarkdown('hello world'), 'hello world');
      });

      test('does nothing to image syntax with regular URLs', () {
        expect(
          normalizeRedditMarkdown('![img](https://example.com/pic.png)'),
          '![img](https://example.com/pic.png)',
        );
      });
    });
  });
}
