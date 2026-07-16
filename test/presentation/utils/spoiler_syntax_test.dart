import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/app_settings.dart';
import 'package:fspez/src/data/auth_providers.dart';
import 'package:fspez/src/presentation/utils/reddit_markdown.dart';
import 'package:fspez/src/presentation/utils/spoiler_syntax.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SpoilerInlineSyntax', () {
    test('parses spoiler-wrapped text into a spoiler element', () {
      const input = 'text before ${spoilerStart}secret${spoilerEnd} text after';
      final document = md.Document(
        inlineSyntaxes: [SpoilerInlineSyntax()],
      );
      final nodes = document.parseLines(input.split('\n'));

      bool foundSpoiler = false;
      void walk(List<md.Node> nodes) {
        for (final node in nodes) {
          if (node is md.Element && node.tag == 'spoiler') {
            foundSpoiler = true;
            final text = node.children
                ?.whereType<md.Text>()
                .map((t) => t.text)
                .join();
            expect(text, 'secret');
          }
          if (node is md.Element && node.children != null) {
            walk(node.children!);
          }
        }
      }
      walk(nodes);
      expect(foundSpoiler, isTrue, reason: 'Expected a spoiler element in AST');
    });

    test('handles multiline spoiler content', () {
      final input = [
        '${spoilerStart}first line',
        'second line$spoilerEnd',
      ].join('\n');
      final document = md.Document(
        inlineSyntaxes: [SpoilerInlineSyntax()],
      );
      final nodes = document.parseLines(input.split('\n'));

      bool foundSpoiler = false;
      void walk(List<md.Node> nodes) {
        for (final node in nodes) {
          if (node is md.Element && node.tag == 'spoiler') {
            foundSpoiler = true;
            final text = node.children
                ?.whereType<md.Text>()
                .map((t) => t.text)
                .join();
            expect(text, 'first line\nsecond line');
          }
          if (node is md.Element && node.children != null) {
            walk(node.children!);
          }
        }
      }
      walk(nodes);
      expect(foundSpoiler, isTrue,
          reason: 'Expected spoiler element for multiline content');
    });
  });

  group('SpoilerElementBuilder', () {
    Future<SharedPreferences> _setupPrefs(bool spoilerBlur) async {
      SharedPreferences.setMockInitialValues({
        'settings.spoilerBlur': spoilerBlur,
      });
      return SharedPreferences.getInstance();
    }

    testWidgets('renders hidden spoiler widget initially',
        (WidgetTester tester) async {
      final prefs = await _setupPrefs(true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPrefsProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MarkdownBody(
                data: normalizeRedditMarkdown('>!hidden text!<'),
                inlineSyntaxes: [SpoilerInlineSyntax()],
                builders: {
                  'spoiler': SpoilerElementBuilder(),
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GestureDetector), findsOneWidget);
      expect(find.text('hidden text'), findsOneWidget);
    });

    testWidgets('reveals spoiler on tap', (WidgetTester tester) async {
      final prefs = await _setupPrefs(true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPrefsProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MarkdownBody(
                data: normalizeRedditMarkdown('>!tap to see!<'),
                inlineSyntaxes: [SpoilerInlineSyntax()],
                builders: {
                  'spoiler': SpoilerElementBuilder(),
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      expect(find.byType(GestureDetector), findsNothing);
      expect(find.text('tap to see'), findsOneWidget);
    });

    testWidgets('shows spoiler immediately when blur is disabled',
        (WidgetTester tester) async {
      final prefs = await _setupPrefs(false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPrefsProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MarkdownBody(
                data: normalizeRedditMarkdown('>!visible!<'),
                inlineSyntaxes: [SpoilerInlineSyntax()],
                builders: {
                  'spoiler': SpoilerElementBuilder(),
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GestureDetector), findsNothing);
      expect(find.text('visible'), findsOneWidget);
    });
  });
}
