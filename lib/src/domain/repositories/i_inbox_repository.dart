import '../models/inbox_feed.dart';
import '../models/session_cookie.dart';

abstract class IInboxRepository {
  Future<InboxFeed> fetchInbox({
    String? after,
    SessionCookie? sessionCookie,
  });

  Future<InboxFeed> fetchUnread({
    String? after,
    SessionCookie? sessionCookie,
  });

  Future<InboxFeed> fetchSent({
    String? after,
    SessionCookie? sessionCookie,
  });

  Future<void> markAsRead(String fullname, SessionCookie sessionCookie);

  Future<void> reply({
    required String fullname,
    required String text,
    required SessionCookie sessionCookie,
  });
}
