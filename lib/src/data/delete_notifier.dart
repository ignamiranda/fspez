import '../domain/models/session_cookie.dart';
import 'interaction_client.dart';
import 'write_operation_notifier.dart';

class DeleteNotifier extends WriteOperationNotifier<void> {
  final InteractionClient _client;

  DeleteNotifier(this._client, super.sessionCookie);

  Future<void> delete(String fullname, SessionCookie cookie) async {
    await write(fullname, null, null,
        () => _client.deleteContent(fullname, cookie));
  }
}
