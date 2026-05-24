import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/inbox_repository.dart';
import 'package:fspez/src/data/reddit_client.dart';
import 'package:fspez/src/domain/models/message_feed.dart';
import 'package:fspez/src/domain/models/session_cookie.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class _MockHttpClient extends Mock implements http.Client {}

void main() {
  late _MockHttpClient mockHttp;
  late RedditClient client;
  late InboxRepository repository;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    mockHttp = _MockHttpClient();
    client = RedditClient(httpClient: mockHttp);
    repository = InboxRepository(client);
  });

  group('fetchInbox', () {
    test('GETs message/inbox endpoint', () async {
      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(jsonEncode({
            'data': {
              'children': [
                {
                  'kind': 't4',
                  'data': {
                    'id': 'm1',
                    'subject': 'Hello',
                    'body': 'Body',
                    'author': 'u1',
                    'dest': 'u2',
                    'created_utc': 1000000000,
                  },
                },
              ],
              'after': 't4_cursor',
              'before': null,
            },
          }), 200));

      final feed = await repository.fetchInbox();

      expect(feed.tab, InboxTab.inbox);
      expect(feed.messages.length, 1);
      expect(feed.messages[0].id, 'm1');
      expect(feed.after, 't4_cursor');
      expect(feed.hasMorePages, true);

      verify(() => mockHttp.get(
            Uri.parse('https://www.reddit.com/message/inbox.json'
                '?limit=25&mark=true'),
            headers: any(named: 'headers'),
          )).called(1);
    });

    test('passes after cursor', () async {
      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(jsonEncode({
            'data': {'children': [], 'after': null, 'before': null},
          }), 200));

      await repository.fetchInbox(after: 't4_cursor');

      verify(() => mockHttp.get(
            Uri.parse('https://www.reddit.com/message/inbox.json'
                '?after=t4_cursor&limit=25&mark=true'),
            headers: any(named: 'headers'),
          )).called(1);
    });
  });

  group('fetchUnread', () {
    test('GETs message/unread endpoint', () async {
      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(jsonEncode({
            'data': {
              'children': [
                {
                  'kind': 't4',
                  'data': {
                    'id': 'm1',
                    'subject': 'Unread',
                    'body': 'Body',
                    'author': 'u1',
                    'dest': 'u2',
                    'created_utc': 1000000000,
                    'new': true,
                  },
                },
              ],
              'after': null,
              'before': null,
            },
          }), 200));

      final feed = await repository.fetchUnread();

      expect(feed.tab, InboxTab.unread);
      expect(feed.messages.length, 1);
      expect(feed.messages[0].isNew, true);

      verify(() => mockHttp.get(
            Uri.parse('https://www.reddit.com/message/unread.json'
                '?limit=25&mark=true'),
            headers: any(named: 'headers'),
          )).called(1);
    });
  });

  group('fetchSent', () {
    test('GETs message/sent endpoint', () async {
      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(jsonEncode({
            'data': {'children': [], 'after': null, 'before': null},
          }), 200));

      final feed = await repository.fetchSent();

      expect(feed.tab, InboxTab.sent);

      verify(() => mockHttp.get(
            Uri.parse('https://www.reddit.com/message/sent.json'
                '?limit=25&mark=true'),
            headers: any(named: 'headers'),
          )).called(1);
    });
  });

  group('error handling', () {
    test('throws RedditApiException on API error', () async {
      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response('Not Found', 404));

      expect(
        () => repository.fetchInbox(),
        throwsA(isA<RedditApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          404,
        )),
      );
    });
  });

  group('cookie forwarding', () {
    test('sends cookie when session provided', () async {
      when(() => mockHttp.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(jsonEncode({
            'data': {'children': [], 'after': null, 'before': null},
          }), 200));

      final cookie = SessionCookie(
        value: 'session_val',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );

      await repository.fetchInbox(sessionCookie: cookie);

      verify(() => mockHttp.get(
            any(),
            headers: {
              'User-Agent': 'fspez/0.1.0',
              'Content-Type': 'application/json',
              'Cookie': 'reddit_session=session_val',
            },
          )).called(1);
    });
  });
}
