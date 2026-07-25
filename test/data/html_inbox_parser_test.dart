import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/html_inbox_parser.dart';
import 'package:fspez/src/domain/models/inbox_feed.dart';
import 'package:fspez/src/domain/models/inbox_item.dart';

void main() {
  late HtmlInboxParser parser;

  setUp(() {
    parser = HtmlInboxParser();
  });

  group('parseInbox', () {
    test('returns empty feed for empty HTML', () {
      final result = parser.parseInbox('', InboxTab.all);
      expect(result.items, isEmpty);
      expect(result.tab, InboxTab.all);
    });

    test('parses DirectMessage from inbox HTML', () {
      const html = '''
        <html>
        <script id="__NEXT_DATA__" type="application/json">
        {
          "props": {
            "pageProps": {
              "messages": [
                {
                  "id": "msg1",
                  "subject": "Hello",
                  "body": "Test message",
                  "author": "sender",
                  "dest": "recipient",
                  "createdUtc": 1700000000,
                  "new": true
                }
              ]
            }
          }
        }
        </script>
        </html>
      ''';
      final result = parser.parseInbox(html, InboxTab.unread);
      expect(result.tab, InboxTab.unread);
      expect(result.items.length, 1);
      expect(result.items[0], isA<DirectMessage>());
      expect(result.items[0].id, 'msg1');
      expect(result.items[0].subject, 'Hello');
      expect(result.items[0].author, 'sender');
      expect(result.items[0].isNew, true);
    });

    test('parses CommentNotification', () {
      const html = '''
        <html>
        <script id="__NEXT_DATA__" type="application/json">
        {
          "props": {
            "pageProps": {
              "messages": [
                {
                  "id": "notif1",
                  "subject": "re: comment",
                  "body": "Someone replied",
                  "author": "replier",
                  "createdUtc": 1700000000,
                  "wasComment": true,
                  "subreddit": "flutter",
                  "score": 5
                }
              ]
            }
          }
        }
        </script>
        </html>
      ''';
      final result = parser.parseInbox(html, InboxTab.all);
      expect(result.items.length, 1);
      expect(result.items[0], isA<CommentNotification>());
      final notif = result.items[0] as CommentNotification;
      expect(notif.subreddit, 'flutter');
      expect(notif.score, 5);
    });

    test('parses after cursor', () {
      const html = '''
        <html>
        <script id="__NEXT_DATA__" type="application/json">
        {
          "props": {
            "pageProps": {
              "messages": [],
              "after": "t3_cursor"
            }
          }
        }
        </script>
        </html>
      ''';
      final result = parser.parseInbox(html, InboxTab.all);
      expect(result.after, 't3_cursor');
    });
  });
}

