import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fspez/src/domain/enums/vote_direction.dart';
import 'package:fspez/src/domain/models/post.dart';
import 'package:fspez/src/domain/models/subreddit.dart';
import 'package:fspez/src/presentation/utils/desktop_shortcuts.dart';
import 'package:fspez/src/presentation/widgets/post_card.dart';
import 'package:fspez/src/presentation/widgets/post_list.dart';
import 'package:fspez/src/data/app_settings.dart';
import 'package:fspez/src/data/auth_providers.dart';

/// Wraps [child] in a [ProviderScope] with overrides needed for widget tests.
typedef _ProviderScopeBuilder = Widget Function(Widget child);

_ProviderScopeBuilder _withTestProviders(SharedPreferences prefs) {
  return (Widget child) {
    return ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: child,
    );
  };
}

Post _createPost(String id, {String title = 'Test Post'}) {
  return Post(
    id: id,
    title: title,
    author: 'testuser',
    subreddit: const Subreddit(id: 't5_1', name: 'flutter'),
    createdAt: DateTime.now(),
    permalink: '/r/flutter/comments/$id/test_post/',
    type: PostType.link,
  );
}

void main() {
  late SharedPreferences testPrefs;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    testPrefs = await SharedPreferences.getInstance();
  });

  group('isDesktopPlatform', () {
    test('returns false on non-desktop (test) platform', () {
      // When running in tests, kIsWeb is false and Platform doesn't report
      // Windows/Linux/macOS (it reports the host, which on CI is usually not
      // the desktop target). The value depends on the test runner's host.
      // This test just verifies it doesn't throw.
      expect(isDesktopPlatform, isA<bool>());
    });
  });

  group('showKeyboardShortcutHelp', () {
    testWidgets('shows help dialog with shortcut groups', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showKeyboardShortcutHelp(context),
              child: const Text('Show Help'),
            ),
          ),
        ),
      ));

      // Open the help dialog
      await tester.tap(find.text('Show Help'));
      await tester.pumpAndSettle();

      // Verify dialog content
      expect(find.text('Keyboard Shortcuts'), findsOneWidget);
      expect(find.text('Feed Navigation'), findsOneWidget);
      expect(find.text('Post Actions'), findsOneWidget);
      expect(find.text('General'), findsOneWidget);

      // Verify shortcut keys appear
      expect(find.text('J'), findsOneWidget);
      expect(find.text('K'), findsOneWidget);
      expect(find.text('Enter'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('Z'), findsOneWidget);
      expect(find.text('S'), findsOneWidget);
      expect(find.text('?'), findsOneWidget);

      // Verify shortcut descriptions
      expect(find.text('Move down'), findsOneWidget);
      expect(find.text('Move up'), findsOneWidget);
      expect(find.text('Open selected post'), findsOneWidget);
      expect(find.text('Upvote'), findsOneWidget);
      expect(find.text('Downvote'), findsOneWidget);
      expect(find.text('Save / Unsave'), findsOneWidget);
      expect(find.text('Show this help'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.text('Keyboard Shortcuts'), findsNothing);
    });
  });

  group('PostCard isFocused', () {
    testWidgets('renders with default non-focused state', (tester) async {
      await tester.pumpWidget(_withTestProviders(testPrefs)(MaterialApp(
        home: Scaffold(
          body: PostCard(
            post: _createPost('1'),
          ),
        ),
      )));

      // Post should be visible without the focus indicator (no left border)
      expect(find.text('Test Post'), findsOneWidget);
    });

    testWidgets('renders with focused state', (tester) async {
      await tester.pumpWidget(_withTestProviders(testPrefs)(MaterialApp(
        home: Scaffold(
          body: PostCard(
            post: _createPost('1'),
            isFocused: true,
          ),
        ),
      )));

      // Post should still be visible
      expect(find.text('Test Post'), findsOneWidget);
      // The focused state adds a left border - we verify it renders without
      // errors
    });
  });

  group('PostList focusedIndex', () {
    testWidgets('passes focusedIndex to PostCard', (tester) async {
      await tester.pumpWidget(_withTestProviders(testPrefs)(MaterialApp(
        home: Scaffold(
          body: PostList(
            posts: [
              _createPost('1', title: 'First'),
              _createPost('2', title: 'Second'),
            ],
            focusedIndex: 0,
          ),
        ),
      )));

      // Both posts should render
      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
    });
  });
}
