import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/comment_parser.dart';
import 'package:fspez/src/domain/enums/vote_direction.dart';

void main() {
  late CommentParser parser;

  setUp(() {
    parser = CommentParser();
  });

  group('parseComments', () {
    test('parses a single top-level comment', () {
      final children = [
        {
          'kind': 't1',
          'data': {
            'id': 'abc123',
            'body': 'This is a comment',
            'author': 'testuser',
            'score': 42,
            'created_utc': 1000000000,
            'depth': 0,
            'collapsed': false,
            'replies': '',
          },
        },
      ];

      final comments = parser.parseComments(children);

      expect(comments.length, 1);
      expect(comments[0].id, 'abc123');
      expect(comments[0].body, 'This is a comment');
      expect(comments[0].author, 'testuser');
      expect(comments[0].score, 42);
      expect(comments[0].depth, 0);
      expect(comments[0].isCollapsed, false);
      expect(comments[0].replies, isEmpty);
    });

    test('parses nested threaded replies', () {
      final children = [
        {
          'kind': 't1',
          'data': {
            'id': 'parent',
            'body': 'Parent comment',
            'author': 'user1',
            'score': 10,
            'created_utc': 1000000000,
            'depth': 0,
            'collapsed': false,
            'replies': {
              'kind': 'Listing',
              'data': {
                'children': [
                  {
                    'kind': 't1',
                    'data': {
                      'id': 'child1',
                      'body': 'Reply to parent',
                      'author': 'user2',
                      'score': 5,
                      'created_utc': 1000000001,
                      'depth': 1,
                      'collapsed': false,
                      'replies': '',
                    },
                  },
                ],
              },
            },
          },
        },
      ];

      final comments = parser.parseComments(children);

      expect(comments.length, 1);
      expect(comments[0].id, 'parent');
      expect(comments[0].replies.length, 1);
      expect(comments[0].replies[0].id, 'child1');
      expect(comments[0].replies[0].body, 'Reply to parent');
      expect(comments[0].replies[0].depth, 1);
    });

    test('handles empty replies string', () {
      final children = [
        {
          'kind': 't1',
          'data': {
            'id': 'a',
            'body': 'No replies',
            'author': 'user',
            'score': 1,
            'created_utc': 1000000000,
            'depth': 0,
            'collapsed': false,
            'replies': '',
          },
        },
      ];

      final comments = parser.parseComments(children);

      expect(comments[0].replies, isEmpty);
    });

    test('handles null replies', () {
      final children = [
        {
          'kind': 't1',
          'data': {
            'id': 'a',
            'body': 'Null replies',
            'author': 'user',
            'score': 1,
            'created_utc': 1000000000,
            'depth': 0,
            'collapsed': false,
          },
        },
      ];

      final comments = parser.parseComments(children);

      expect(comments[0].replies, isEmpty);
    });

    test('skips non-t1 children (e.g. "more")', () {
      final children = [
        {
          'kind': 't1',
          'data': {
            'id': 'a',
            'body': 'Real comment',
            'author': 'user',
            'score': 1,
            'created_utc': 1000000000,
            'depth': 0,
            'collapsed': false,
            'replies': '',
          },
        },
        {
          'kind': 'more',
          'data': {'count': 5, 'parent_id': 't1_a'},
        },
      ];

      final comments = parser.parseComments(children);

      expect(comments.length, 1);
      expect(comments[0].id, 'a');
    });

    test('parses vote direction from likes', () {
      final children = [
        {
          'kind': 't1',
          'data': {
            'id': '1',
            'body': 'Upvoted',
            'author': 'u',
            'score': 1,
            'created_utc': 1000000000,
            'depth': 0,
            'collapsed': false,
            'likes': true,
            'replies': '',
          },
        },
        {
          'kind': 't1',
          'data': {
            'id': '2',
            'body': 'Downvoted',
            'author': 'u',
            'score': 1,
            'created_utc': 1000000001,
            'depth': 0,
            'collapsed': false,
            'likes': false,
            'replies': '',
          },
        },
        {
          'kind': 't1',
          'data': {
            'id': '3',
            'body': 'No vote',
            'author': 'u',
            'score': 1,
            'created_utc': 1000000002,
            'depth': 0,
            'collapsed': false,
            'replies': '',
          },
        },
      ];

      final comments = parser.parseComments(children);

      expect(comments[0].vote, VoteDirection.upvote);
      expect(comments[1].vote, VoteDirection.downvote);
      expect(comments[2].vote, VoteDirection.none);
    });

    test('parses distinguished moderator', () {
      final children = [
        {
          'kind': 't1',
          'data': {
            'id': 'm',
            'body': 'Mod comment',
            'author': 'mod',
            'score': 1,
            'created_utc': 1000000000,
            'depth': 0,
            'collapsed': false,
            'distinguished': 'moderator',
            'replies': '',
          },
        },
        {
          'kind': 't1',
          'data': {
            'id': 'u',
            'body': 'User comment',
            'author': 'user',
            'score': 1,
            'created_utc': 1000000001,
            'depth': 0,
            'collapsed': false,
            'replies': '',
          },
        },
      ];

      final comments = parser.parseComments(children);

      expect(comments[0].isModerator, true);
      expect(comments[1].isModerator, false);
    });

    test('parses is_submitter flag', () {
      final children = [
        {
          'kind': 't1',
          'data': {
            'id': 'a',
            'body': 'OP comment',
            'author': 'op',
            'score': 1,
            'created_utc': 1000000000,
            'depth': 0,
            'collapsed': false,
            'is_submitter': true,
            'replies': '',
          },
        },
        {
          'kind': 't1',
          'data': {
            'id': 'b',
            'body': 'Other comment',
            'author': 'other',
            'score': 1,
            'created_utc': 1000000001,
            'depth': 0,
            'collapsed': false,
            'replies': '',
          },
        },
      ];

      final comments = parser.parseComments(children);

      expect(comments[0].isSubmitter, true);
      expect(comments[1].isSubmitter, false);
    });

    test('parses award count', () {
      final children = [
        {
          'kind': 't1',
          'data': {
            'id': 'a',
            'body': 'Awarded comment',
            'author': 'user',
            'score': 1,
            'created_utc': 1000000000,
            'depth': 0,
            'collapsed': false,
            'total_awards_received': 2,
            'replies': '',
          },
        },
      ];

      final comments = parser.parseComments(children);

      expect(comments[0].awardCount, 2);
    });

    test('parses saved and stickied flags', () {
      final children = [
        {
          'kind': 't1',
          'data': {
            'id': 'a',
            'body': 'Saved',
            'author': 'u',
            'score': 1,
            'created_utc': 1000000000,
            'depth': 0,
            'collapsed': false,
            'saved': true,
            'stickied': true,
            'replies': '',
          },
        },
      ];

      final comments = parser.parseComments(children);

      expect(comments[0].isSaved, true);
      expect(comments[0].isStickied, true);
    });

    test('handles deleted author', () {
      final children = [
        {
          'kind': 't1',
          'data': {
            'id': 'a',
            'body': 'Deleted user',
            'score': 1,
            'created_utc': 1000000000,
            'depth': 0,
            'collapsed': false,
            'replies': '',
          },
        },
      ];

      final comments = parser.parseComments(children);

      expect(comments[0].author, '[deleted]');
    });

    test('returns empty list for empty input', () {
      expect(parser.parseComments([]), isEmpty);
    });

    test('parses createdAt correctly', () {
      final children = [
        {
          'kind': 't1',
          'data': {
            'id': 'a',
            'body': 'Test',
            'author': 'u',
            'score': 1,
            'created_utc': 1000000000,
            'depth': 0,
            'collapsed': false,
            'replies': '',
          },
        },
      ];

      final comments = parser.parseComments(children);

      expect(
        comments[0].createdAt,
        DateTime.fromMillisecondsSinceEpoch(1000000000000),
      );
    });
  });
}
