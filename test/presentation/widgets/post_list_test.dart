import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fspez/src/domain/enums/vote_direction.dart';
import 'package:fspez/src/domain/models/post.dart';
import 'package:fspez/src/domain/models/subreddit.dart';
import 'package:fspez/src/presentation/widgets/post_list.dart';
import 'package:fspez/src/data/app_settings.dart';
import 'package:fspez/src/data/auth_providers.dart';

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

/// Wraps [child] in a [ProviderScope] with overrides needed for widget tests
/// that exercise [PostCard] (which reads [appSettingsProvider]).
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

void main() {
  late SharedPreferences testPrefs;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    testPrefs = await SharedPreferences.getInstance();
  });

  group('PostList', () {
    testWidgets('renders posts', (tester) async {
      await tester.pumpWidget(_withTestProviders(testPrefs)(MaterialApp(
        home: Scaffold(
          body: PostList(
            posts: [_createPost('1'), _createPost('2')],
          ),
        ),
      )));

      expect(find.text('Test Post'), findsNWidgets(2));
    });

    testWidgets('shows empty message when no posts', (tester) async {
      await tester.pumpWidget(_withTestProviders(testPrefs)(MaterialApp(
        home: Scaffold(
          body: PostList(
            posts: [],
            emptyMessage: 'Nothing here.',
          ),
        ),
      )));

      expect(find.text('Nothing here.'), findsOneWidget);
    });

    testWidgets('calls onPostTap when post is tapped', (tester) async {
      Post? tapped;
      await tester.pumpWidget(_withTestProviders(testPrefs)(MaterialApp(
        home: Scaffold(
          body: PostList(
            posts: [_createPost('1')],
            onPostTap: (post) => tapped = post,
          ),
        ),
      )));

      await tester.tap(find.text('Test Post'));
      expect(tapped?.id, '1');
    });

    testWidgets('calls onRefresh when dragged past the top', (tester) async {
      var refreshed = false;
      await tester.pumpWidget(_withTestProviders(testPrefs)(MaterialApp(
        home: Scaffold(
          body: PostList(
            posts: [_createPost('1')],
            onRefresh: () async {
              refreshed = true;
            },
          ),
        ),
      )));

      await tester.drag(find.byType(ListView), const Offset(0, 300));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(refreshed, isTrue);
    });

    testWidgets('shows empty state and still allows onRefresh', (tester) async {
      await tester.pumpWidget(_withTestProviders(testPrefs)(MaterialApp(
        home: Scaffold(
          body: PostList(
            posts: [],
            onRefresh: () async {},
            emptyMessage: 'No posts.',
          ),
        ),
      )));

      expect(find.text('No posts.'), findsOneWidget);
    });

    testWidgets('calls onPostVote when vote button is tapped', (tester) async {
      String? votedFullname;
      VoteDirection? votedDirection;
      await tester.pumpWidget(_withTestProviders(testPrefs)(MaterialApp(
        home: Scaffold(
          body: PostList(
            posts: [_createPost('1')],
            onPostVote: (fullname, dir) {
              votedFullname = fullname;
              votedDirection = dir;
            },
          ),
        ),
      )));

      await tester.tap(find.byIcon(Icons.arrow_upward_outlined));
      expect(votedFullname, 't3_1');
      expect(votedDirection, VoteDirection.upvote);
    });

    testWidgets('exposes semantic labels for post actions', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(_withTestProviders(testPrefs)(MaterialApp(
          home: Scaffold(
            body: PostList(
              posts: [_createPost('1')],
            ),
          ),
        )));

        expect(find.bySemanticsLabel('Upvote'), findsOneWidget);
        expect(find.bySemanticsLabel('Downvote'), findsOneWidget);
        expect(find.bySemanticsLabel('Save'), findsOneWidget);
        expect(find.bySemanticsLabel('More actions'), findsOneWidget);
      } finally {
        semantics.dispose();
      }
    });
  });
}
