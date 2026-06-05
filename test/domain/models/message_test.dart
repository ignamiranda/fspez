import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/domain/enums/vote_direction.dart';
import 'package:fspez/src/domain/models/inbox_item.dart';

void main() {
  group('DirectMessage', () {
    test('creates with default values', () {
      final message = DirectMessage(
        id: 'msg1',
        subject: 'Hello',
        body: 'Body text',
        author: 'sender',
        dest: 'recipient',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1000000000000),
      );

      expect(message.id, 'msg1');
      expect(message.subject, 'Hello');
      expect(message.body, 'Body text');
      expect(message.author, 'sender');
      expect(message.dest, 'recipient');
      expect(message.isNew, false);
      expect(message.replies, isEmpty);
      expect(message.fullname, 't4_msg1');
    });

    test('equality', () {
      final a = DirectMessage(
        id: 'm1',
        subject: 'Subj',
        body: 'Body',
        author: 'u1',
        dest: 'u2',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1000000000000),
      );
      final b = DirectMessage(
        id: 'm1',
        subject: 'Subj',
        body: 'Body',
        author: 'u1',
        dest: 'u2',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1000000000000),
      );
      final c = DirectMessage(
        id: 'm2',
        subject: 'Subj',
        body: 'Body',
        author: 'u1',
        dest: 'u2',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1000000000000),
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('fullname uses t4 prefix', () {
      final message = DirectMessage(
        id: 'abc123',
        subject: '',
        body: '',
        author: 'u',
        dest: 'v',
        createdAt: DateTime.now(),
      );

      expect(message.fullname, 't4_abc123');
    });

    test('supports nested replies', () {
      final reply = DirectMessage(
        id: 'reply1',
        subject: 'Re: Hello',
        body: 'Reply body',
        author: 'original',
        dest: 'sender',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1000000001000),
      );

      final parent = DirectMessage(
        id: 'msg1',
        subject: 'Hello',
        body: 'Parent body',
        author: 'sender',
        dest: 'recipient',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1000000000000),
        replies: [reply],
      );

      expect(parent.replies.length, 1);
      expect(parent.replies[0].id, 'reply1');
      expect((parent.replies[0] as DirectMessage).fullname, 't4_reply1');
    });

    test('is not a CommentNotification', () {
      final message = DirectMessage(
        id: 'm1',
        subject: '',
        body: '',
        author: 'u',
        dest: 'v',
        createdAt: DateTime.now(),
      );

      expect(message, isA<InboxItem>());
      expect(message, isNot(isA<CommentNotification>()));
      expect(message, isA<DirectMessage>());
    });
  });

  group('CommentNotification', () {
    test('creates with default values', () {
      final cn = CommentNotification(
        id: 'c1',
        subject: 'comment reply',
        body: 'Nice post!',
        author: 'commenter',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1000000000000),
      );

      expect(cn.id, 'c1');
      expect(cn.subject, 'comment reply');
      expect(cn.body, 'Nice post!');
      expect(cn.author, 'commenter');
      expect(cn.isNew, false);
      expect(cn.replies, isEmpty);
      expect(cn.vote, VoteDirection.none);
      expect(cn.score, 0);
      expect(cn.fullname, 't1_c1');
    });

    test('equality', () {
      final a = CommentNotification(
        id: 'c1',
        subject: 're',
        body: 'body',
        author: 'u1',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1000000000000),
        subreddit: 'flutter',
        score: 5,
      );
      final b = CommentNotification(
        id: 'c1',
        subject: 're',
        body: 'body',
        author: 'u1',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1000000000000),
        subreddit: 'flutter',
        score: 5,
      );
      final c = CommentNotification(
        id: 'c2',
        subject: 're',
        body: 'body',
        author: 'u1',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1000000000000),
        subreddit: 'flutter',
        score: 5,
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('fullname uses t1 prefix', () {
      final cn = CommentNotification(
        id: 'abc123',
        subject: '',
        body: '',
        author: 'u',
        createdAt: DateTime.now(),
      );

      expect(cn.fullname, 't1_abc123');
    });

    test('is not a DirectMessage', () {
      final cn = CommentNotification(
        id: 'c1',
        subject: '',
        body: '',
        author: 'u',
        createdAt: DateTime.now(),
      );

      expect(cn, isA<InboxItem>());
      expect(cn, isNot(isA<DirectMessage>()));
      expect(cn, isA<CommentNotification>());
    });
  });
}
