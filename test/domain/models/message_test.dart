import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/domain/enums/vote_direction.dart';
import 'package:fspez/src/domain/models/message.dart';

void main() {
  group('Message', () {
    test('creates with default values', () {
      final message = Message(
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
      expect(message.isComment, false);
      expect(message.replies, isEmpty);
      expect(message.vote, VoteDirection.none);
      expect(message.score, 0);
      expect(message.fullname, 't4_msg1');
    });

    test('equality', () {
      final a = Message(
        id: 'm1',
        subject: 'Subj',
        body: 'Body',
        author: 'u1',
        dest: 'u2',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1000000000000),
      );
      final b = Message(
        id: 'm1',
        subject: 'Subj',
        body: 'Body',
        author: 'u1',
        dest: 'u2',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1000000000000),
      );
      final c = Message(
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
      final message = Message(
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
      final reply = Message(
        id: 'reply1',
        subject: 'Re: Hello',
        body: 'Reply body',
        author: 'original',
        dest: 'sender',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1000000001000),
      );

      final parent = Message(
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
      expect(parent.replies[0].fullname, 't4_reply1');
    });
  });
}
