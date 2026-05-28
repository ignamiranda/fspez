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
  });
}
