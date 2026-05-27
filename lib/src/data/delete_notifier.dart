import '../domain/models/session_cookie.dart';
import 'write_operation_notifier.dart';

class DeleteNotifier extends WriteOperationNotifier<void> {
  DeleteNotifier(super.redditClient, super.sessionCookie);

  Future<void> delete(String fullname, SessionCookie cookie) async {
    await write(fullname, null, null,
        () => redditClient.deleteContent(fullname, cookie));
  }
}
