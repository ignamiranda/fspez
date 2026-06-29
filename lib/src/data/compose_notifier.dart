import '../domain/models/session_cookie.dart';
import 'message_client.dart';
import 'write_notifier.dart';

class ComposeNotifier extends WriteNotifier {
  final MessageClient _client;

  ComposeNotifier(this._client);

  Future<bool> send({
    required Map<String, String> fields,
    required SessionCookie sessionCookie,
  }) {
    return execute(() => _client.compose(fields: fields, sessionCookie: sessionCookie));
  }
}
