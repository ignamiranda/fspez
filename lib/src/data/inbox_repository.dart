import '../domain/models/inbox_feed.dart';
import '../domain/models/session_cookie.dart';
import '../domain/repositories/i_inbox_repository.dart';
import 'reddit_client.dart';
import 'inbox_parser.dart';
import 'message_client.dart';

class InboxRepository implements IInboxRepository {
  final RedditClient _client;
  final MessageClient _messageClient;
  final InboxParser _parser;

  InboxRepository(this._client, this._messageClient, {InboxParser? parser})
      : _parser = parser ?? InboxParser();

  @override
  Future<InboxFeed> fetchInbox({
    String? after,
    SessionCookie? sessionCookie,
  }) {
    return _fetch('/message/inbox', InboxTab.all, after,
        sessionCookie: sessionCookie);
  }

  @override
  Future<InboxFeed> fetchUnread({
    String? after,
    SessionCookie? sessionCookie,
  }) {
    return _fetch('/message/unread', InboxTab.unread, after,
        sessionCookie: sessionCookie);
  }

  @override
  Future<InboxFeed> fetchSent({
    String? after,
    SessionCookie? sessionCookie,
  }) {
    return _fetch('/message/sent', InboxTab.sent, after,
        sessionCookie: sessionCookie);
  }

  Future<InboxFeed> _fetch(
    String path,
    InboxTab tab,
    String? after, {
    SessionCookie? sessionCookie,
  }) async {
    final data = await _client.get(path,
        queryParams: {
          if (after != null) 'after': after,
          'limit': '25',
          'mark': 'true',
        },
        sessionCookie: sessionCookie);

    final listing = data['data'] as Map<String, dynamic>;
    final children = listing['children'] as List<dynamic>;
    final messages = _parser.parseMessages(children);

    return InboxFeed(
      tab: tab,
      items: messages,
      after: listing['after'] as String?,
      before: listing['before'] as String?,
    );
  }

  @override
  Future<void> markAsRead(
    String fullname,
    SessionCookie sessionCookie,
  ) async {
    await _client.postForm('/api/read_message',
        fields: {
          'id': fullname,
          'uh': sessionCookie.modhash ?? '',
        },
        sessionCookie: sessionCookie);
  }

  @override
  Future<void> reply({
    required String fullname,
    required String text,
    required SessionCookie sessionCookie,
  }) async {
    await _messageClient.comment(
      fields: {
        'thing_id': fullname,
        'text': text,
        'uh': sessionCookie.modhash ?? '',
      },
      sessionCookie: sessionCookie,
    );
  }
}
