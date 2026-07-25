import '../domain/models/inbox_feed.dart';
import '../domain/models/session_cookie.dart';
import 'html_inbox_parser.dart';
import 'reddit_client.dart';
import 'message_client.dart';

class InboxRepository {
  final RedditClient _client;
  final MessageClient _messageClient;

  InboxRepository(this._client, this._messageClient);

  Future<InboxFeed> fetchInbox({
    String? after,
    SessionCookie? sessionCookie,
  }) {
    return _fetch('/message/inbox', InboxTab.all, after,
        sessionCookie: sessionCookie);
  }

  Future<InboxFeed> fetchUnread({
    String? after,
    SessionCookie? sessionCookie,
  }) {
    return _fetch('/message/unread', InboxTab.unread, after,
        sessionCookie: sessionCookie);
  }

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
    final params = <String, String>{
      'mark': 'true',
      if (after != null) 'after': after,
    };
    final html = await _client.getHtml(path,
        queryParams: params, sessionCookie: sessionCookie);
    return HtmlInboxParser().parseInbox(html, tab);
  }

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
