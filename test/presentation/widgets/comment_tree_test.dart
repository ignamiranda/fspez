import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/domain/models/comment.dart';
import 'package:fspez/src/presentation/widgets/comment_tree.dart';

Comment _comment({
  required String id,
  String body = 'Comment body',
  String author = 'user',
  int score = 5,
  int depth = 0,
  List<Comment> replies = const [],
  bool isCollapsed = false,
}) {
  return Comment(
    id: id,
    body: body,
    author: author,
    score: score,
    createdAt: DateTime.now(),
    postId: 't3_post1',
    parentId: depth > 0 ? 't1_parent' : null,
    depth: depth,
    replies: replies,
    isCollapsed: isCollapsed,
  );
}

Widget _wrap(Widget widget) => MaterialApp(home: Scaffold(body: widget));

void main() {
  group('CommentTree', () {
    testWidgets('renders comment body', (tester) async {
      await tester.pumpWidget(_wrap(CommentTree(
        comment: _comment(id: '1', body: 'Hello world'),
      )));

      expect(find.text('Hello world'), findsOneWidget);
      expect(find.text('u/user'), findsOneWidget);
      expect(find.text('5 pts'), findsOneWidget);
    });

    testWidgets('hides body and actions when collapsed via tap',
        (tester) async {
      await tester.pumpWidget(_wrap(CommentTree(
        comment: _comment(id: '1', body: 'Collapsible comment'),
      )));

      expect(find.text('Collapsible comment'), findsOneWidget);

      // Tap score text (not author name) to collapse
      await tester.tap(find.text('5 pts'));
      await tester.pumpAndSettle();

      expect(find.text('Collapsible comment'), findsNothing);
    });

    testWidgets('hides replies when collapsed and shows when tapped again',
        (tester) async {
      final reply =
          _comment(id: '2', body: 'Reply text', author: 'replyuser', depth: 1);
      await tester.pumpWidget(_wrap(CommentTree(
        comment: _comment(
            id: '1', body: 'Parent', author: 'parentuser', replies: [reply]),
      )));

      expect(find.text('Reply text'), findsOneWidget);

      // Tap parent score to collapse (reply is expanded, so both "5 pts" are visible)
      await tester.tap(find.text('5 pts').first);
      await tester.pumpAndSettle();

      expect(find.text('Reply text'), findsNothing);

      // Tap parent score to expand (only parent's "5 pts" visible now)
      await tester.tap(find.text('5 pts'));
      await tester.pumpAndSettle();

      expect(find.text('Reply text'), findsOneWidget);
    });

    testWidgets('author tap navigates when expanded, expands when collapsed',
        (tester) async {
      String? tappedAuthor;
      await tester.pumpWidget(_wrap(CommentTree(
        comment: _comment(id: '1', body: 'Author test'),
        onAuthorTap: (author) => tappedAuthor = author,
      )));

      // Expanded: author tap navigates (does not collapse)
      await tester.tap(find.text('u/user'));
      expect(tappedAuthor, 'user');
      expect(find.text('Author test'), findsOneWidget);

      // Collapse via score tap
      await tester.tap(find.text('5 pts'));
      await tester.pumpAndSettle();
      expect(find.text('Author test'), findsNothing);

      // Collapsed: author tap expands (does not navigate)
      tappedAuthor = null;
      await tester.tap(find.text('u/user'));
      await tester.pumpAndSettle();
      expect(tappedAuthor, isNull);
      expect(find.text('Author test'), findsOneWidget);
    });

    testWidgets('collapsed comment expands when tapping whitespace',
        (tester) async {
      await tester.pumpWidget(_wrap(CommentTree(
        comment: _comment(id: '1', body: 'Whitespace tap body'),
      )));

      // Collapse via score tap
      await tester.tap(find.text('5 pts'));
      await tester.pumpAndSettle();

      // Tap the row GestureDetector (first one) to expand
      final rect = tester.getRect(find.byType(GestureDetector).first);
      await tester.tapAt(Offset(rect.left + 8, rect.bottom - 8));
      await tester.pumpAndSettle();

      expect(find.text('Whitespace tap body'), findsOneWidget);
    });

    testWidgets('respects API collapsed state as initial', (tester) async {
      await tester.pumpWidget(_wrap(CommentTree(
        comment:
            _comment(id: '1', body: 'Initially collapsed', isCollapsed: true),
      )));

      expect(find.text('Initially collapsed'), findsNothing);
    });

    testWidgets('user tap toggles even when API collapsed', (tester) async {
      await tester.pumpWidget(_wrap(CommentTree(
        comment: _comment(id: '1', body: 'API collapsed', isCollapsed: true),
      )));

      expect(find.text('API collapsed'), findsNothing);

      await tester.tap(find.text('5 pts'));
      await tester.pumpAndSettle();

      expect(find.text('API collapsed'), findsOneWidget);
    });

    testWidgets('shallow comments at depth < kMaxCommentDepth render normally',
        (tester) async {
      final deepReply = _comment(
        id: '3',
        body: 'Deep reply',
        author: 'deep',
        depth: kMaxCommentDepth + 1,
      );
      final reply = _comment(
        id: '2',
        body: 'Reply at depth 1',
        author: 'reply',
        depth: 1,
        replies: [deepReply],
      );

      await tester.pumpWidget(_wrap(CommentTree(
        comment: _comment(id: '1', body: 'Top', replies: [reply]),
      )));

      // Reply at depth 1 should render
      expect(find.text('Reply at depth 1'), findsOneWidget);
    });

    testWidgets('truncates comments at depth >= kMaxCommentDepth',
        (tester) async {
      final deepReply = _comment(
        id: '3',
        body: 'Deep reply body',
        author: 'deep',
        depth: kMaxCommentDepth + 1,
      );

      await tester.pumpWidget(_wrap(CommentTree(
        comment: _comment(id: '1', body: 'Top', replies: [deepReply]),
      )));

      // The deep reply body should NOT be visible — truncated
      expect(find.text('Deep reply body'), findsNothing);
    });

    testWidgets('shows Continue this thread link when replies are truncated',
        (tester) async {
      final deepReply = _comment(
        id: '3',
        body: 'Hidden deep reply',
        author: 'deep',
        depth: kMaxCommentDepth + 1,
      );

      await tester.pumpWidget(_wrap(CommentTree(
        comment: _comment(id: '1', body: 'Top', replies: [deepReply]),
      )));

      expect(find.textContaining('Continue this thread'), findsOneWidget);
      expect(find.textContaining('1 more reply'), findsOneWidget);
    });

    testWidgets('tapping Continue this thread expands truncated replies',
        (tester) async {
      final deepReply = _comment(
        id: '3',
        body: 'Now visible deep reply',
        author: 'deep',
        depth: kMaxCommentDepth + 1,
      );

      await tester.pumpWidget(_wrap(CommentTree(
        comment: _comment(id: '1', body: 'Top', replies: [deepReply]),
      )));

      expect(find.text('Now visible deep reply'), findsNothing);

      // Tap "Continue this thread"
      await tester.tap(find.textContaining('Continue this thread'));
      await tester.pumpAndSettle();

      // Now the deep reply should be visible
      expect(find.text('Now visible deep reply'), findsOneWidget);
    });

    testWidgets('shows total count in Continue this thread link',
        (tester) async {
      final deepReply1 = _comment(
        id: 'r1',
        body: 'Hidden 1',
        author: 'deep',
        depth: kMaxCommentDepth + 1,
      );
      final deepReply2 = _comment(
        id: 'r2',
        body: 'Hidden 2',
        author: 'deep',
        depth: kMaxCommentDepth + 1,
        replies: [
          _comment(
            id: 'r3',
            body: 'Hidden 3',
            author: 'deep',
            depth: kMaxCommentDepth + 2,
          ),
        ],
      );

      await tester.pumpWidget(_wrap(CommentTree(
        comment:
            _comment(id: '1', body: 'Top', replies: [deepReply1, deepReply2]),
      )));

      // Total: 3 hidden (2 direct + 1 nested)
      expect(find.textContaining('3 more replies'), findsOneWidget);
    });
  });
}
