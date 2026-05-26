import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/domain/enums/vote_direction.dart';
import 'package:fspez/src/domain/models/post.dart';
import 'package:fspez/src/domain/models/subreddit.dart';
import 'package:fspez/src/presentation/widgets/post_list.dart';

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
  group('PostList', () {
    testWidgets('renders posts', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PostList(
            posts: [_createPost('1'), _createPost('2')],
          ),
        ),
      ));

      expect(find.text('Test Post'), findsNWidgets(2));
    });

    testWidgets('shows empty message when no posts', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: PostList(
            posts: [],
            emptyMessage: 'Nothing here.',
          ),
        ),
      ));

      expect(find.text('Nothing here.'), findsOneWidget);
    });

    testWidgets('calls onPostTap when post is tapped', (tester) async {
      Post? tapped;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PostList(
            posts: [_createPost('1')],
            onPostTap: (post) => tapped = post,
          ),
        ),
      ));

      await tester.tap(find.text('Test Post'));
      expect(tapped?.id, '1');
    });

    testWidgets('calls onRefresh when dragged past the top', (tester) async {
      var refreshed = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PostList(
            posts: [_createPost('1')],
            onRefresh: () async {
              refreshed = true;
            },
          ),
        ),
      ));

      await tester.drag(find.byType(ListView), const Offset(0, 300));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(refreshed, isTrue);
    });

    testWidgets('shows empty state and still allows onRefresh', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PostList(
            posts: [],
            onRefresh: () async {},
            emptyMessage: 'No posts.',
          ),
        ),
      ));

      expect(find.text('No posts.'), findsOneWidget);
    });

    testWidgets('calls onPostVote when vote button is tapped', (tester) async {
      String? votedFullname;
      VoteDirection? votedDirection;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PostList(
            posts: [_createPost('1')],
            onPostVote: (fullname, dir) {
              votedFullname = fullname;
              votedDirection = dir;
            },
          ),
        ),
      ));

      await tester.tap(find.byIcon(Icons.arrow_upward_outlined));
      expect(votedFullname, 't3_1');
      expect(votedDirection, VoteDirection.upvote);
    });
  });
}
