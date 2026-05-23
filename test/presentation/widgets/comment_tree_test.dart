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

    testWidgets('hides body and actions when collapsed via tap', (tester) async {
      await tester.pumpWidget(_wrap(CommentTree(
        comment: _comment(id: '1', body: 'Collapsible comment'),
      )));

      expect(find.text('Collapsible comment'), findsOneWidget);

      await tester.tap(find.text('u/user'));
      await tester.pumpAndSettle();

      expect(find.text('Collapsible comment'), findsNothing);
    });

    testWidgets('hides replies when collapsed and shows when tapped again',
        (tester) async {
      final reply = _comment(id: '2', body: 'Reply text', author: 'replyuser', depth: 1);
      await tester.pumpWidget(_wrap(CommentTree(
        comment: _comment(id: '1', body: 'Parent', author: 'parentuser', replies: [reply]),
      )));

      expect(find.text('Reply text'), findsOneWidget);

      await tester.tap(find.text('u/parentuser'));
      await tester.pumpAndSettle();

      expect(find.text('Reply text'), findsNothing);

      await tester.tap(find.text('u/parentuser'));
      await tester.pumpAndSettle();

      expect(find.text('Reply text'), findsOneWidget);
    });

    testWidgets('shows unfold icon when collapsed', (tester) async {
      await tester.pumpWidget(_wrap(CommentTree(
        comment: _comment(id: '1', body: 'Body'),
      )));

      expect(find.byIcon(Icons.unfold_more), findsNothing);

      await tester.tap(find.text('u/user'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.unfold_more), findsOneWidget);
    });

    testWidgets('collapsed comment sliver expands when tapping whitespace',
        (tester) async {
      await tester.pumpWidget(_wrap(CommentTree(
        comment: _comment(id: '1', body: 'Whitespace tap body'),
      )));

      await tester.tap(find.text('u/user'));
      await tester.pumpAndSettle();

      final rect = tester.getRect(find.byType(GestureDetector).first);
      await tester.tapAt(Offset(rect.left + 8, rect.bottom - 8));
      await tester.pumpAndSettle();

      expect(find.text('Whitespace tap body'), findsOneWidget);
    });

    testWidgets('respects API collapsed state as initial', (tester) async {
      await tester.pumpWidget(_wrap(CommentTree(
        comment: _comment(id: '1', body: 'Initially collapsed', isCollapsed: true),
      )));

      expect(find.text('Initially collapsed'), findsNothing);
      expect(find.byIcon(Icons.unfold_more), findsOneWidget);
    });

    testWidgets('user tap toggles even when API collapsed', (tester) async {
      await tester.pumpWidget(_wrap(CommentTree(
        comment: _comment(id: '1', body: 'API collapsed', isCollapsed: true),
      )));

      expect(find.text('API collapsed'), findsNothing);

      await tester.tap(find.byIcon(Icons.unfold_more));
      await tester.pumpAndSettle();

      expect(find.text('API collapsed'), findsOneWidget);
    });
  });
}
