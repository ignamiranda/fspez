import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'reddit_client.dart';
import '../domain/models/session_cookie.dart';

class HideNotifier extends StateNotifier<Set<String>> {
  final RedditClient _client;
  final SessionCookie? _cookie;

  HideNotifier(this._client, this._cookie) : super({});

  Future<void> toggle(String fullname) async {
    final hidden = state.contains(fullname);
    if (hidden) return;
    state = {...state, fullname};
    try {
      final sc = _cookie;
      if (sc == null) return;
      await _client.hide(fullname, sc);
    } catch (_) {
      state = {...state}..remove(fullname);
    }
  }

  void dismiss(String fullname) {
    if (state.contains(fullname)) {
      state = {...state}..remove(fullname);
    }
  }
}
