import '../domain/models/session_cookie.dart';
import 'reddit_client.dart';

enum SubmitKind { self, link }

class SubmitRepository {
  final RedditClient _client;

  SubmitRepository(this._client);

  Future<void> submit({
    required SubmitKind kind,
    required String subreddit,
    required String title,
    String? text,
    String? url,
    required SessionCookie sessionCookie,
  }) async {
    final fields = <String, String>{
      'kind': kind == SubmitKind.self ? 'self' : 'link',
      'sr': subreddit,
      'title': title,
      'uh': sessionCookie.modhash ?? '',
    };
    if (kind == SubmitKind.self && text != null) {
      fields['text'] = text;
    }
    if (kind == SubmitKind.link && url != null) {
      fields['url'] = url;
    }
    await _client.submit(fields: fields, sessionCookie: sessionCookie);
  }
}
