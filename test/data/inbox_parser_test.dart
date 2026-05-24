import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/inbox_parser.dart';
import 'package:fspez/src/domain/enums/vote_direction.dart';

void main() {
  late InboxParser parser;

  setUp(() {
    parser = InboxParser();
  });

  group('parseMessages', () {
    test('returns empty list for empty children', () {
      final result = parser.parseMessages([]);
      expect(result, isEmpty);
    });

    test('accepts both t4 (messages) and t1 (comment replies) kinds', () {
      final children = [
        {'kind': 't3', 'data': {'id': 'post1'}},
        {'kind': 't4', 'data': {
          'id': 'msg1',
          'subject': 'PM',
          'body': 'Private message',
          'author': 'sender',
          'dest': 'recipient',
          'created_utc': 1000000000,
        }},
        {'kind': 't1', 'data': {
          'id': 'onfi1lw',
          'subject': 'comment reply',
          'body': 'Jeff Goldbugg',
          'author': 'Euphoric_Oven_9918',
          'dest': 'CodenameAwesome',
          'created_utc': 1779544805,
          'new': true,
          'was_comment': true,
          'subreddit': 'cooladam',
        }},
      ];

      final result = parser.parseMessages(children);

      expect(result.length, 2);
      expect(result[0].id, 'msg1');
      expect(result[1].id, 'onfi1lw');
      expect(result[1].subject, 'comment reply');
      expect(result[1].isComment, true);
      expect(result[1].subreddit, 'cooladam');
    });

    test('parses all message fields from JSON', () {
      final children = [
        {'kind': 't4', 'data': {
          'id': 'msg1',
          'subject': 'Test Subject',
          'body': 'Message body content',
          'author': 'testuser',
          'dest': 'me',
          'created_utc': 1000000000,
          'new': true,
          'was_comment': true,
          'subreddit': 'flutter',
          'distinguished': 'moderator',
          'likes': true,
          'score': 5,
          'context': '/r/flutter/comments/abc/test/',
          'first_message_name': 't4_first1',
          'parent_id': null,
        }},
      ];

      final result = parser.parseMessages(children);

      expect(result.length, 1);
      final msg = result[0];
      expect(msg.id, 'msg1');
      expect(msg.subject, 'Test Subject');
      expect(msg.body, 'Message body content');
      expect(msg.author, 'testuser');
      expect(msg.dest, 'me');
      expect(msg.isNew, true);
      expect(msg.isComment, true);
      expect(msg.subreddit, 'flutter');
      expect(msg.distinguished, 'moderator');
      expect(msg.vote, VoteDirection.upvote);
      expect(msg.score, 5);
      expect(msg.context, '/r/flutter/comments/abc/test/');
      expect(msg.firstMessageName, 't4_first1');
      expect(msg.parentId, isNull);
      expect(
        msg.createdAt,
        DateTime.fromMillisecondsSinceEpoch(1000000000 * 1000),
      );
    });

    test('parses nested replies', () {
      final children = [
        {'kind': 't4', 'data': {
          'id': 'parent',
          'subject': 'Hello',
          'body': 'Parent body',
          'author': 'u1',
          'dest': 'u2',
          'created_utc': 1000000000,
          'replies': {
            'kind': 'Listing',
            'data': {
              'children': [
                {'kind': 't4', 'data': {
                  'id': 'reply1',
                  'subject': 'Re: Hello',
                  'body': 'Reply body',
                  'author': 'u2',
                  'dest': 'u1',
                  'created_utc': 1000000001,
                }},
                {'kind': 't4', 'data': {
                  'id': 'reply2',
                  'subject': 'Re: Hello',
                  'body': 'Second reply',
                  'author': 'u2',
                  'dest': 'u1',
                  'created_utc': 1000000002,
                }},
              ],
            },
          },
        }},
      ];

      final result = parser.parseMessages(children);

      expect(result.length, 1);
      expect(result[0].id, 'parent');
      expect(result[0].replies.length, 2);
      expect(result[0].replies[0].id, 'reply1');
      expect(result[0].replies[0].body, 'Reply body');
      expect(result[0].replies[1].id, 'reply2');
      expect(result[0].replies[1].body, 'Second reply');
    });

    test('handles empty string replies', () {
      final children = [
        {'kind': 't4', 'data': {
          'id': 'msg1',
          'subject': 'No replies',
          'body': 'Body',
          'author': 'u1',
          'dest': 'u2',
          'created_utc': 1000000000,
          'replies': '',
        }},
      ];

      final result = parser.parseMessages(children);

      expect(result.length, 1);
      expect(result[0].replies, isEmpty);
    });

    test('handles missing fields with defaults', () {
      final children = [
        {'kind': 't4', 'data': {
          'id': 'minimal',
          'created_utc': 1000000000,
        }},
      ];

      final result = parser.parseMessages(children);

      expect(result.length, 1);
      final msg = result[0];
      expect(msg.id, 'minimal');
      expect(msg.subject, '(no subject)');
      expect(msg.body, '');
      expect(msg.author, '[deleted]');
      expect(msg.dest, '');
      expect(msg.isNew, false);
      expect(msg.isComment, false);
      expect(msg.vote, VoteDirection.none);
      expect(msg.score, 0);
    });

    test('removes non-matching entries (t3, more, etc.)', () {
      final children = [
        {'kind': 'more', 'data': {'count': 3}},
        {'kind': 't3', 'data': {'id': 'post1'}},
        {'kind': 't4', 'data': {
          'id': 'msg1',
          'subject': 'S',
          'body': 'B',
          'author': 'u',
          'dest': 'v',
          'created_utc': 1000000000,
        }},
      ];

      final result = parser.parseMessages(children);

      expect(result.length, 1);
      expect(result[0].id, 'msg1');
    });
  });
}
