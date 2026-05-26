import 'package:fspez/src/data/session_store.dart';

class FakeCookieProvider implements CookieProvider {
  String? _cookieValue;
  String? _cookieString;

  FakeCookieProvider({String? cookieValue, String? cookieString})
      : _cookieValue = cookieValue,
        _cookieString = cookieString;

  @override
  Future<String?> getRedditSessionValue() async => _cookieValue;

  @override
  Future<String?> getCookieString() async =>
      _cookieString ?? (_cookieValue != null ? 'reddit_session=$_cookieValue' : null);

  void setValue(String? value) => _cookieValue = value;

  void setCookieString(String? value) => _cookieString = value;
}
