import '../domain/models/session_cookie.dart';
import 'interaction_client.dart';
import 'write_notifier.dart';

class EditNotifier extends WriteNotifier {
  final InteractionClient _client;

  EditNotifier(this._client);

  String? get error => state.error;

  Future<bool> edit(String thingId, String text, SessionCookie cookie) {
    return execute(
      () => _client.editContent(thingId: thingId, text: text, sessionCookie: cookie),
    );
  }
}
